#!/usr/bin/env python3
"""
Convert gold FSI JSON (CopyCultivateAPItoBlob) to Power BI-compatible CSV.

Supports two modes:
  --full     : Full export (default). Overwrites CSV with all records.
  --incremental : Compare against existing CSV. Only new IDs get today's
                  date_checked. Existing records keep their original values.

Input:  data/gold/CopyCultivateAPItoBlob  (JSON)
Output: data/gold/mart_fsi_powerbi_export.csv (flat CSV, 21 columns)

After running, load into Snowflake via:
  snowflake/07_powerbi_export.sql
"""

import json
import csv
import argparse
from datetime import date
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
INPUT_FILE = PROJECT_ROOT / "data" / "gold" / "CopyCultivateAPItoBlob"
OUTPUT_FILE = PROJECT_ROOT / "data" / "gold" / "mart_fsi_powerbi_export.csv"

COLUMNS = [
    "id", "city", "country", "name", "url",
    "facebook_url", "twitter_url", "instagram_url",
    "food_sharing_activities", "how_it_is_shared",
    "date_checked", "lat", "lon", "round",
    "growing", "distribution", "cooking_eating",
    "gifting", "collecting", "selling", "bartering",
]


def load_existing_csv():
    """Load existing CSV into a dict keyed by id."""
    if not OUTPUT_FILE.exists():
        return {}
    existing = {}
    with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            existing[row["id"]] = row
    return existing


def transform_fsi(fsi, date_checked_value):
    """Transform a single FSI JSON record to a flat CSV row."""
    activities = fsi.get("foodSharingActivities", [])
    sharing = fsi.get("howItIsShared", [])

    return {
        "id": fsi["id"],
        "city": fsi.get("city", ""),
        "country": fsi.get("country", ""),
        "name": fsi.get("name", ""),
        "url": fsi.get("url", ""),
        "facebook_url": fsi.get("facebookUrl", "") or "",
        "twitter_url": fsi.get("xUrl", "") or "",
        "instagram_url": fsi.get("instagramUrl", "") or "",
        "food_sharing_activities": ";".join(activities),
        "how_it_is_shared": ";".join(sharing),
        "date_checked": date_checked_value,
        "lat": fsi.get("lat", ""),
        "lon": fsi.get("lng", ""),
        "round": "",
        "growing": 1 if "Growing" in activities else 0,
        "distribution": 1 if "Distribution" in activities else 0,
        "cooking_eating": 1 if "Cooking & Eating" in activities else 0,
        "gifting": 1 if "Gifting" in sharing else 0,
        "collecting": 1 if "Collecting" in sharing else 0,
        "selling": 1 if "Selling" in sharing else 0,
        "bartering": 1 if "Bartering" in sharing else 0,
    }


def convert(incremental=False):
    with open(INPUT_FILE, "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    fsis = data["data"]
    today = date.today().strftime("%d/%m/%Y")

    print(f"Loaded {len(fsis)} FSIs from {INPUT_FILE}")

    if incremental:
        existing = load_existing_csv()
        print(f"Existing CSV has {len(existing)} records")

        new_count = 0
        updated_count = 0
        rows = []

        for fsi in fsis:
            fsi_id = fsi["id"]
            if fsi_id in existing:
                # Keep existing record (preserve original date_checked)
                rows.append(existing[fsi_id])
                updated_count += 1
            else:
                # New record: set date_checked = today
                rows.append(transform_fsi(fsi, today))
                new_count += 1

        print(f"  Existing (kept): {updated_count}")
        print(f"  New (added):     {new_count}")

    else:
        # Full mode: all records get today's date_checked
        rows = [transform_fsi(fsi, today) for fsi in fsis]

    with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Written {len(rows)} rows to {OUTPUT_FILE}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert gold FSI JSON to Power BI CSV")
    parser.add_argument(
        "--incremental",
        action="store_true",
        help="Incremental mode: only set date_checked for new IDs",
    )
    args = parser.parse_args()
    convert(incremental=args.incremental)
