"""
Dead link checker — reusable for any CSV of URLs on S3.

Accepts either a single CSV (`--input s3://bucket/path.csv`) or a prefix
of CSVs (`--input-prefix s3://bucket/folder/`). Results are written to
`--output s3://bucket/report.csv` with columns: city, name, url,
status_code, alive.

Alive = HTTP 200–399, or 403/405/406 (servers that block HEAD but are live).

Usage:
    python scripts/check_dead_links.py \\
        --input s3://cultivate-mapping-data/raw/manual_verified/Manual\\ mapping/SHARECITY100_webdata/SHARECITY100_oldweb_data.csv \\
        --output s3://cultivate-mapping-data/raw/exploration_data/2026_data/04_SHARECITY100/dead_link_report_oldweb.csv \\
        --url-col url --city-col cityName --name-col enterpriseName
"""

import argparse
import csv
import io
import sys
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlparse

import boto3
import requests

ALIVE_EXTRA = {403, 405, 406}


def parse_s3_url(s3_url: str) -> tuple[str, str]:
    p = urlparse(s3_url)
    if p.scheme != "s3":
        raise ValueError(f"Not an s3:// URL: {s3_url}")
    return p.netloc, p.path.lstrip("/")


def list_csv_keys(s3, bucket: str, prefix: str) -> list[str]:
    keys = []
    paginator = s3.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        keys.extend(
            obj["Key"] for obj in page.get("Contents", [])
            if obj["Key"].lower().endswith(".csv")
        )
    return keys


def read_csv(s3, bucket: str, key: str) -> list[dict]:
    body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8-sig")
    return list(csv.DictReader(io.StringIO(body)))


def extract_rows(rows: list[dict], url_col: str, city_col: str, name_col: str
                 ) -> list[tuple[str, str, str]]:
    out = []
    for row in rows:
        url = (row.get(url_col) or "").strip()
        if not url:
            continue
        out.append((
            (row.get(city_col) or "").strip(),
            (row.get(name_col) or "").strip(),
            url,
        ))
    return out


def check_url(url: str, timeout: float) -> int:
    try:
        r = requests.head(url, timeout=timeout, allow_redirects=True,
                          headers={"User-Agent": "Mozilla/5.0"})
        return r.status_code
    except requests.RequestException:
        return 0


def is_alive(status: int) -> bool:
    return 200 <= status < 400 or status in ALIVE_EXTRA


def main():
    ap = argparse.ArgumentParser(description="Dead link checker for S3-hosted CSVs.")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--input", help="s3://bucket/path/to/file.csv")
    src.add_argument("--input-prefix", help="s3://bucket/folder/  (all *.csv under it)")
    ap.add_argument("--output", required=True, help="s3://bucket/path/to/report.csv")
    ap.add_argument("--url-col", default="url", help="CSV column with URL (default: url)")
    ap.add_argument("--city-col", default="city", help="CSV column with city (default: city)")
    ap.add_argument("--name-col", default="name", help="CSV column with name (default: name)")
    ap.add_argument("--region", default="eu-north-1")
    ap.add_argument("--timeout", type=float, default=10.0)
    ap.add_argument("--workers", type=int, default=10)
    args = ap.parse_args()

    s3 = boto3.client("s3", region_name=args.region)

    # gather rows from input(s)
    if args.input:
        bucket, key = parse_s3_url(args.input)
        rows = read_csv(s3, bucket, key)
    else:
        bucket, prefix = parse_s3_url(args.input_prefix)
        keys = list_csv_keys(s3, bucket, prefix)
        print(f"Found {len(keys)} CSV files under {args.input_prefix}", file=sys.stderr)
        rows = []
        for k in keys:
            rows.extend(read_csv(s3, bucket, k))

    records = extract_rows(rows, args.url_col, args.city_col, args.name_col)
    print(f"URLs to check: {len(records)}", file=sys.stderr)

    # check in parallel
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        statuses = list(pool.map(lambda r: check_url(r[2], args.timeout), records))

    alive_count = sum(1 for s in statuses if is_alive(s))
    print(f"Alive: {alive_count}/{len(statuses)}", file=sys.stderr)

    # write report
    out_bucket, out_key = parse_s3_url(args.output)
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(["city", "name", "url", "status_code", "alive"])
    for (city, name, url), status in zip(records, statuses):
        writer.writerow([city, name, url, status, is_alive(status)])
    s3.put_object(Bucket=out_bucket, Key=out_key, Body=buf.getvalue().encode("utf-8"))
    print(f"Saved: s3://{out_bucket}/{out_key}", file=sys.stderr)


if __name__ == "__main__":
    main()
