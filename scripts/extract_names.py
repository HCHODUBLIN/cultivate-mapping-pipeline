"""
Extract the organisation's own (local-language) name from scraped page
content using the OpenAI Agents SDK (gpt-5-nano by default).

The 2016 SHARECITY names were translated to English; the automation tool
also stripped accents. This recovers the name as the initiative writes it
itself, from the page <title> and body text.

Input S3 CSV needs: city, url, page_title, scraped_text (name optional).
Output: city, url, english_name, local_name, error. Resumable.

Usage:
    python scripts/extract_names.py \\
        --input  s3://cultivate-mapping-data/raw/sharecity100/2016/scraped.csv \\
        --output s3://cultivate-mapping-data/raw/sharecity100/2016/names.csv
"""

import argparse
import asyncio
import csv
import io
import os
import sys
from urllib.parse import urlparse

import boto3
from agents import Agent, Runner
from dotenv import load_dotenv
from pydantic import BaseModel

load_dotenv()

FIELDNAMES = ["city", "url", "english_name", "local_name", "error"]


class NameExtraction(BaseModel):
    local_name: str


INSTRUCTIONS = """
You are given the <title> tag and body text scraped from a food sharing
initiative's website, plus the English name a researcher previously assigned.

Return the initiative's own name exactly as it appears on its website — in
its original local language and script, with correct accents/diacritics
(e.g. Körnerkiez, Fundación, Café, 협동조합).

Rules:
- Prefer the name as written in the page title or prominent heading.
- Do NOT translate. Do NOT transliterate. Keep the native script.
- Strip site-suffix noise ("| Home", "- Willkommen", domain names).
- If the page gives no clear organisation name, return the English name unchanged.
- Return only the name, no quotes or extra words.
"""


def parse_s3_url(s3_url: str) -> tuple[str, str]:
    p = urlparse(s3_url)
    if p.scheme != "s3":
        raise ValueError(f"Not an s3:// URL: {s3_url}")
    return p.netloc, p.path.lstrip("/")


def read_csv_from_s3(s3, bucket: str, key: str) -> list[dict]:
    body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8-sig")
    return list(csv.DictReader(io.StringIO(body)))


def append_result(s3, bucket: str, key: str, row: dict) -> None:
    try:
        existing = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8")
    except s3.exceptions.NoSuchKey:
        existing = ",".join(FIELDNAMES) + "\n"
    buf = io.StringIO(existing)
    buf.seek(0, io.SEEK_END)
    csv.DictWriter(buf, fieldnames=FIELDNAMES).writerow(row)
    s3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode("utf-8"))


async def extract(model: str, english_name: str, title: str, text: str) -> str:
    agent = Agent(
        name="Local Name Extractor",
        model=model,
        instructions=INSTRUCTIONS,
        output_type=NameExtraction,
    )
    user_input = (
        f"English name: {english_name}\n\n"
        f"Page title: {title}\n\n"
        f"Body text:\n{text[:3000]}"
    )
    result = await Runner.run(agent, user_input)
    return result.final_output.local_name


async def main_async(args):
    if not os.environ.get("OPENAI_API_KEY"):
        sys.exit("OPENAI_API_KEY not set (check .env or environment).")
    model = os.environ.get("OPENAI_MODEL", "gpt-5-nano")

    s3 = boto3.client("s3", region_name=args.region)
    in_bucket, in_key = parse_s3_url(args.input)
    out_bucket, out_key = parse_s3_url(args.output)

    rows = read_csv_from_s3(s3, in_bucket, in_key)
    # only rows with some scraped content to work from
    rows = [r for r in rows if (r.get("page_title") or r.get("scraped_text", "").strip())]
    print(f"Rows with content: {len(rows)}", file=sys.stderr)

    done_urls: set[str] = set()
    try:
        done = read_csv_from_s3(s3, out_bucket, out_key)
        done_urls = {r["url"] for r in done if r.get("url")}
        print(f"Resuming — {len(done_urls)} already done", file=sys.stderr)
    except s3.exceptions.NoSuchKey:
        pass

    todo = [r for r in rows if r.get(args.url_col) not in done_urls]
    print(f"To extract: {len(todo)}", file=sys.stderr)
    if not todo:
        return

    for i, r in enumerate(todo, start=1):
        city = r.get(args.city_col, "")
        url = r.get(args.url_col, "")
        english_name = r.get(args.name_col, "")
        try:
            local_name = await extract(
                model, english_name,
                r.get("page_title", ""), r.get("scraped_text", ""),
            )
            append_result(s3, out_bucket, out_key, {
                "city": city, "url": url, "english_name": english_name,
                "local_name": local_name, "error": "",
            })
            print(f"[{i}/{len(todo)}] {city} | {english_name[:30]} → {local_name[:40]}", file=sys.stderr)
        except Exception as e:
            append_result(s3, out_bucket, out_key, {
                "city": city, "url": url, "english_name": english_name,
                "local_name": "", "error": str(e)[:200],
            })
            print(f"[{i}/{len(todo)}] {city} | {url[:50]} → ERROR: {e}", file=sys.stderr)

    print("Done!", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--input", required=True, help="s3://… scraped CSV (city,url,page_title,scraped_text)")
    ap.add_argument("--output", required=True, help="s3://… output CSV (resumable)")
    ap.add_argument("--url-col", default="url")
    ap.add_argument("--city-col", default="city")
    ap.add_argument("--name-col", default="name")
    ap.add_argument("--region", default="eu-north-1")
    args = ap.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
