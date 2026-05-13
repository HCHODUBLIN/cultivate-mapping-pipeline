"""
Geocode FSI records via Google Places Text Search (New).

Reads an S3 CSV with at least name + city + country (column names configurable),
queries the Places API with `"<name> in <city>, <country>"`, and picks the best
of the top 5 results by SequenceMatcher similarity on the returned displayName.

Output schema:
    id, name, city, country, place_id, matched_name, similarity, lat, lng

Notes
-----
- FieldMask = `places.id,places.displayName,places.location` keeps each call on
  the cheaper Basic SKU ($0.032 / request as of 2026-04).
- Resumes from an existing output CSV — already-geocoded rows (matched by id)
  are skipped, so you can safely re-run after a crash.
- Set GOOGLE_PLACES_API_KEY in .env or the environment.

Usage
-----
    python scripts/geocode_places.py \\
        --input  s3://cultivate-mapping-data/raw/sharecity100/2016/to_geocode.csv \\
        --output s3://cultivate-mapping-data/raw/sharecity100/2016/geocoded.csv \\
        --name-col enterpriseName \\
        --city-col city \\
        --country-col country
"""

import argparse
import csv
import io
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from difflib import SequenceMatcher
from urllib.parse import urlparse

import boto3
import requests
from dotenv import load_dotenv

load_dotenv()

PLACES_URL = "https://places.googleapis.com/v1/places:searchText"
FIELD_MASK = "places.id,places.displayName,places.location"
FIELDNAMES = ["id", "name", "city", "country",
              "place_id", "matched_name", "similarity", "lat", "lng"]


def parse_s3_url(s3_url: str) -> tuple[str, str]:
    p = urlparse(s3_url)
    if p.scheme != "s3":
        raise ValueError(f"Not an s3:// URL: {s3_url}")
    return p.netloc, p.path.lstrip("/")


def read_csv_from_s3(s3, bucket: str, key: str) -> list[dict]:
    body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8-sig")
    return list(csv.DictReader(io.StringIO(body)))


def write_csv_to_s3(s3, bucket: str, key: str, rows: list[dict]) -> None:
    buf = io.StringIO()
    writer = csv.DictWriter(buf, fieldnames=FIELDNAMES)
    writer.writeheader()
    writer.writerows(rows)
    s3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode("utf-8"))


def geocode(name: str, city: str, country: str, api_key: str,
            max_retries: int = 5
            ) -> tuple[str | None, str | None, float | None, float | None, float | None]:
    """Return (place_id, matched_name, similarity, lat, lng); all None on failure.

    Retries with exponential backoff on 429 (rate-limit) and 5xx responses.
    """
    import time

    if not name or not city:
        return None, None, None, None, None

    query = f"{name} in {city}, {country}".strip(", ")

    for attempt in range(max_retries):
        try:
            r = requests.post(
                PLACES_URL,
                headers={
                    "Content-Type": "application/json",
                    "X-Goog-Api-Key": api_key,
                    "X-Goog-FieldMask": FIELD_MASK,
                },
                json={"textQuery": query, "pageSize": 5},
                timeout=15,
            )
            if r.status_code == 429 or r.status_code >= 500:
                wait = 2 ** attempt  # 1, 2, 4, 8, 16 seconds
                time.sleep(wait)
                continue
            r.raise_for_status()
            break
        except requests.RequestException as e:
            if attempt == max_retries - 1:
                print(f"  giving up '{query}': {e}", file=sys.stderr)
                return None, None, None, None, None
            time.sleep(2 ** attempt)
    else:
        return None, None, None, None, None

    places = r.json().get("places", [])
    if not places:
        return None, None, None, None, None

    name_lower = name.lower()

    def sim(p):
        return SequenceMatcher(None, name_lower, p["displayName"]["text"].lower()).ratio()

    best = max(places, key=sim)
    loc = best.get("location") or {}
    return (
        best.get("id"),
        best["displayName"]["text"],
        round(sim(best), 3),
        loc.get("latitude"),
        loc.get("longitude"),
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--input", required=True, help="s3://bucket/path/to/input.csv")
    ap.add_argument("--output", required=True, help="s3://bucket/path/to/geocoded.csv")
    ap.add_argument("--id-col", default="id")
    ap.add_argument("--name-col", default="name")
    ap.add_argument("--city-col", default="city")
    ap.add_argument("--country-col", default="country")
    ap.add_argument("--region", default="eu-north-1")
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--save-every", type=int, default=100)
    args = ap.parse_args()

    api_key = os.environ.get("GOOGLE_PLACES_API_KEY")
    if not api_key:
        sys.exit("GOOGLE_PLACES_API_KEY not set (check .env or environment).")

    s3 = boto3.client("s3", region_name=args.region)
    in_bucket, in_key = parse_s3_url(args.input)
    out_bucket, out_key = parse_s3_url(args.output)

    input_rows = read_csv_from_s3(s3, in_bucket, in_key)
    print(f"Input rows: {len(input_rows)}", file=sys.stderr)

    done_ids: set[str] = set()
    existing: list[dict] = []
    try:
        existing = read_csv_from_s3(s3, out_bucket, out_key)
        done_ids = {r["id"] for r in existing if r.get("id")}
        print(f"Resuming — {len(done_ids)} rows already geocoded", file=sys.stderr)
    except s3.exceptions.NoSuchKey:
        pass

    todo = [r for r in input_rows if r.get(args.id_col) not in done_ids]
    print(f"To geocode: {len(todo)}", file=sys.stderr)
    if not todo:
        print("Nothing to do.", file=sys.stderr)
        return

    def process(row):
        return geocode(row.get(args.name_col, ""),
                       row.get(args.city_col, ""),
                       row.get(args.country_col, ""),
                       api_key)

    results = list(existing)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for i, (row, geo) in enumerate(zip(todo, pool.map(process, todo)), start=1):
            place_id, matched_name, similarity, lat, lng = geo
            results.append({
                "id": row.get(args.id_col),
                "name": row.get(args.name_col),
                "city": row.get(args.city_col),
                "country": row.get(args.country_col),
                "place_id": place_id,
                "matched_name": matched_name,
                "similarity": similarity,
                "lat": lat,
                "lng": lng,
            })
            if i % args.save_every == 0:
                write_csv_to_s3(s3, out_bucket, out_key, results)
                print(f"  [{i}/{len(todo)}] checkpoint saved", file=sys.stderr)

    write_csv_to_s3(s3, out_bucket, out_key, results)
    print(f"Done. Saved: s3://{out_bucket}/{out_key}", file=sys.stderr)


if __name__ == "__main__":
    main()
