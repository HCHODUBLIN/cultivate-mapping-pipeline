"""
Classify scraped webpage text as a valid Food Sharing Initiative (FSI) using
the OpenAI Agents SDK (gpt-5-nano by default).

Reads an S3 CSV with city + name + url + scraped_text columns, writes one
classification per URL to the output S3 CSV with valid/confidence/reason fields.

Resumes from existing output (skips URLs already classified). Country is
looked up from a city → country CSV (also on S3).

Usage:
    python scripts/classify_with_scraped_text.py \\
        --input   s3://cultivate-mapping-data/raw/sharecity100/2024/to_classify.csv \\
        --output  s3://cultivate-mapping-data/raw/sharecity100/2024/classified.csv \\
        --cities  s3://cultivate-mapping-data/raw/metadata/city_list.csv
"""

import argparse
import asyncio
import csv
import io
import os
import sys
from typing import Literal
from urllib.parse import urlparse

import boto3
from agents import Agent, Runner
from dotenv import load_dotenv
from pydantic import BaseModel

load_dotenv()


class Classification(BaseModel):
    valid: bool
    confidence: Literal["low", "medium", "high"]
    reason: str


def build_instructions(city: str, country: str) -> str:
    return f"""
Task: Classify whether the given webpage text represents a valid Food Sharing Initiative (FSI) located in {city}, {country}.

You will receive the URL and pre-scraped text from the webpage. Base your classification strictly on this text.

Method (Strict Evidence-Based Evaluation):
1. Extract only explicit textual evidence from the provided text.
   Treat all claims as unverified unless directly supported by the text.

2. Do not infer or assume intentions based on tone, imagery, branding, or general community-oriented language.

3. Before producing output, internally evaluate (do not reveal this reasoning):
   - each VALID criterion as Confirmed, Contradicted, or Not found
   - each INVALID trigger
   - final decision based strictly on explicit evidence

4. If the text is insufficient, blank, or irrelevant, classify as INVALID with low confidence.

VALID FSI — All Six Conditions Must Be Explicitly Confirmed:

1. Direct representation:
   The website is owned by or officially represents the initiative, not a media site, directory, listing, or article.

2. Explicit food-sharing purpose:
   The site clearly states that the initiative performs food redistribution or communal food sharing, such as:
   - food rescue
   - free or pay-what-you-can meals
   - community kitchens
   - shared gardens where harvest is distributed or collectively available
   - seed/produce swaps
   - non-commercial food cooperatives
   General mentions of sustainability, community, or ecology are insufficient without explicit food-sharing activities.

3. Active food-sharing operations:
   Evidence shows ongoing or recurring food distribution or communal food-sharing activities (not a one-time event).

4. Non-commercial:
   The initiative's primary purpose is community food access, not sales or profit-making.

5. Location match:
   The initiative explicitly states an address or operational activity in {city}, {country}.
   Nearby cities, regions, or generic national presence do not qualify.

6. Evidence of continuity:
   Clear indication of recurring or ongoing programs (events, schedules, regular services).

If any required condition is "Not found", classify as INVALID.

INVALID FSI — Any One of These Is Sufficient:

- News, media, editorial, or blog content describing an initiative.
- Government or municipal pages listing external programs without operating them.
- Crowdfunding or campaign-only pages (GoFundMe, Kickstarter, etc.).
- Social media profiles without a verifiable organizational website.
- Restaurants, cafes, or food-delivery or food-retail businesses.
- Schools or cultural institutions hosting only one-off food events.
- Gardening, farming, ecology, or sustainability groups without explicit food sharing or redistribution.
- Multi-city or international networks without confirmed operations in {city}, {country}.
- Any page with insufficient evidence, ambiguous purpose, or inaccessible/empty content.

Edge Cases:

- Community centers, libraries, churches: Valid only if food sharing is a core, ongoing activity explicitly stated.
- Gardening groups: Valid only if the harvest is shared or redistributed, not merely grown.
- Coalitions or networks: Valid only if they coordinate actual food-sharing activity, not just advocacy or education.

Confidence Scoring:

- High: All required evidence is explicit, consistent, and unambiguous.
- Medium: Most evidence is explicit, but one secondary attribute (e.g., frequency or non-commercial nature) is implied.
- Low: Missing or ambiguous evidence; unclear location; partial page retrieval; or overall uncertainty.

Reason:
- Provide a concise 1-2 sentence explanation citing the specific criteria that were confirmed or missing.
"""


def parse_s3_url(s3_url: str) -> tuple[str, str]:
    p = urlparse(s3_url)
    if p.scheme != "s3":
        raise ValueError(f"Not an s3:// URL: {s3_url}")
    return p.netloc, p.path.lstrip("/")


def read_csv_from_s3(s3, bucket: str, key: str) -> list[dict]:
    body = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8-sig")
    return list(csv.DictReader(io.StringIO(body)))


def append_result(s3, bucket: str, key: str, row: dict, fieldnames: list[str]) -> None:
    """Append a row to a CSV on S3 (read-modify-write)."""
    try:
        existing = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode("utf-8")
    except s3.exceptions.NoSuchKey:
        existing = ",".join(fieldnames) + "\n"

    buf = io.StringIO(existing)
    buf.seek(0, io.SEEK_END)
    writer = csv.DictWriter(buf, fieldnames=fieldnames)
    writer.writerow(row)
    s3.put_object(Bucket=bucket, Key=key, Body=buf.getvalue().encode("utf-8"))


async def classify(model: str, city: str, country: str, url: str, text: str) -> Classification:
    agent = Agent(
        name="FSI Classifier (text-based)",
        model=model,
        instructions=build_instructions(city, country),
        output_type=Classification,
    )
    user_input = f"URL: {url}\n\nScraped text:\n{text}"
    result = await Runner.run(agent, user_input)
    return result.final_output


async def main_async(args):
    if not os.environ.get("OPENAI_API_KEY"):
        sys.exit("OPENAI_API_KEY not set (check .env or environment).")
    model = os.environ.get("OPENAI_MODEL", "gpt-5-nano")

    s3 = boto3.client("s3", region_name=args.region)
    in_bucket, in_key = parse_s3_url(args.input)
    out_bucket, out_key = parse_s3_url(args.output)
    cities_bucket, cities_key = parse_s3_url(args.cities)

    # 1. city → country lookup
    city_rows = read_csv_from_s3(s3, cities_bucket, cities_key)
    city_country = {r["City"]: r["Country"] for r in city_rows if r.get("City")}
    print(f"Loaded {len(city_country)} city-country mappings", file=sys.stderr)

    # 2. input rows
    input_rows = read_csv_from_s3(s3, in_bucket, in_key)
    scraped = [
        (r["city"], r["name"], r["url"], r.get("scraped_text", ""))
        for r in input_rows if r.get("scraped_text", "").strip()
    ]
    print(f"URLs with scraped text: {len(scraped)}", file=sys.stderr)

    # 3. resume from checkpoint
    done_urls: set[str] = set()
    try:
        done = read_csv_from_s3(s3, out_bucket, out_key)
        done_urls = {r["url"] for r in done if r.get("url")}
        print(f"Resuming — {len(done_urls)} URLs already classified", file=sys.stderr)
    except s3.exceptions.NoSuchKey:
        pass

    remaining = [item for item in scraped if item[2] not in done_urls]
    print(f"Remaining: {len(remaining)} URLs", file=sys.stderr)
    if not remaining:
        return

    fieldnames = ["city", "name", "url", "valid", "confidence", "reason", "error"]

    for i, (city, name, url, text) in enumerate(remaining, start=1):
        country = city_country.get(city, "")
        try:
            result = await classify(model, city, country, url, text)
            append_result(s3, out_bucket, out_key, {
                "city": city, "name": name, "url": url,
                "valid": result.valid, "confidence": result.confidence,
                "reason": result.reason, "error": "",
            }, fieldnames)
            print(f"[{i}/{len(remaining)}] {city} | {url[:60]} → valid={result.valid}, conf={result.confidence}", file=sys.stderr)
        except Exception as e:
            append_result(s3, out_bucket, out_key, {
                "city": city, "name": name, "url": url,
                "valid": "", "confidence": "", "reason": "", "error": str(e)[:200],
            }, fieldnames)
            print(f"[{i}/{len(remaining)}] {city} | {url[:60]} → ERROR: {e}", file=sys.stderr)

    print("Done!", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--input", required=True, help="s3://… input CSV (city,name,url,scraped_text)")
    ap.add_argument("--output", required=True, help="s3://… output CSV (resumable)")
    ap.add_argument("--cities", required=True, help="s3://… city → country lookup CSV")
    ap.add_argument("--region", default="eu-north-1")
    args = ap.parse_args()
    asyncio.run(main_async(args))


if __name__ == "__main__":
    main()
