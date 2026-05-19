"""
Scrape page text + <title> for a list of URLs on S3.

Reads an S3 CSV (any columns, must include a URL column), fetches each URL,
and writes city, name, url, page_title, scraped_text to the output CSV.
page_title is the raw <title> tag (good source for the local-language name);
scraped_text is the cleaned body text (first 5000 chars).

Resumable — already-scraped URLs (matched on url) are skipped.

Usage:
    python scripts/scrape_text.py \\
        --input  s3://cultivate-mapping-data/raw/sharecity100/2016/fsi_2016.csv \\
        --output s3://cultivate-mapping-data/raw/sharecity100/2016/scraped.csv
"""

import argparse
import csv
import io
import sys
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlparse

import boto3
import requests
from bs4 import BeautifulSoup

FIELDNAMES = ["city", "name", "url", "page_title", "scraped_text"]


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


def scrape(url: str, timeout: int = 15) -> tuple[str, str]:
    """Return (page_title, body_text). Empty strings on failure."""
    try:
        r = requests.get(url, timeout=timeout, headers={"User-Agent": "Mozilla/5.0"})
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "html.parser")
        title = soup.title.string.strip() if soup.title and soup.title.string else ""
        for tag in soup(["script", "style", "nav", "footer", "header"]):
            tag.decompose()
        text = soup.get_text(separator=" ", strip=True)
        return title, text[:5000]
    except Exception:
        return "", ""


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--input", required=True, help="s3://… input CSV")
    ap.add_argument("--output", required=True, help="s3://… output CSV (resumable)")
    ap.add_argument("--url-col", default="url")
    ap.add_argument("--city-col", default="city")
    ap.add_argument("--name-col", default="name")
    ap.add_argument("--region", default="eu-north-1")
    ap.add_argument("--workers", type=int, default=10)
    ap.add_argument("--save-every", type=int, default=100)
    args = ap.parse_args()

    s3 = boto3.client("s3", region_name=args.region)
    in_bucket, in_key = parse_s3_url(args.input)
    out_bucket, out_key = parse_s3_url(args.output)

    rows = read_csv_from_s3(s3, in_bucket, in_key)
    targets = [
        (r.get(args.city_col, ""), r.get(args.name_col, ""), r[args.url_col].strip())
        for r in rows if r.get(args.url_col, "").strip()
    ]
    print(f"Input URLs: {len(targets)}", file=sys.stderr)

    done_urls: set[str] = set()
    results: list[dict] = []
    try:
        existing = read_csv_from_s3(s3, out_bucket, out_key)
        done_urls = {r["url"] for r in existing if r.get("url")}
        results = existing
        print(f"Resuming — {len(done_urls)} already scraped", file=sys.stderr)
    except s3.exceptions.NoSuchKey:
        pass

    todo = [t for t in targets if t[2] not in done_urls]
    print(f"To scrape: {len(todo)}", file=sys.stderr)
    if not todo:
        return

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for i, ((city, name, url), (title, text)) in enumerate(
            zip(todo, pool.map(lambda t: scrape(t[2]), todo)), start=1
        ):
            results.append({
                "city": city, "name": name, "url": url,
                "page_title": title, "scraped_text": text,
            })
            if i % args.save_every == 0:
                write_csv_to_s3(s3, out_bucket, out_key, results)
                print(f"  [{i}/{len(todo)}] checkpoint saved", file=sys.stderr)

    write_csv_to_s3(s3, out_bucket, out_key, results)
    empty = sum(1 for r in results if not r["scraped_text"])
    print(f"Done. {len(results)} rows ({empty} empty). Saved: s3://{out_bucket}/{out_key}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
