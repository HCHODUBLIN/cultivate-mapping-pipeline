"""
Convert mart_fsi_powerbi_export.csv → gold_fsi_final.csv

Reverse-transforms the Power BI flat export back to gold_fsi_final format:
- Semicolon-separated activities → JSON arrays
- twitter_url → x_url
- lon → lng
- Drops Power BI-specific columns (date_checked, round, boolean flags)
"""

import csv
import json
import os

INPUT = os.path.join(os.path.dirname(__file__), "../../data/gold/mart_fsi_powerbi_export.csv")
OUTPUT = os.path.join(os.path.dirname(__file__), "../../data/gold/gold_fsi_final.csv")

GOLD_COLUMNS = [
    "id", "name", "url", "facebook_url", "x_url", "instagram_url",
    "food_sharing_activities", "how_it_is_shared",
    "country", "city", "lng", "lat"
]


def semicolon_to_json_array(value: str) -> str:
    """Convert semicolon-separated string to JSON array string."""
    if not value or not value.strip():
        return "[]"
    items = [item.strip() for item in value.split(";") if item.strip()]
    return json.dumps(items)


def main():
    rows_written = 0
    with open(INPUT, "r", encoding="utf-8") as fin, \
         open(OUTPUT, "w", encoding="utf-8", newline="") as fout:

        reader = csv.DictReader(fin)
        writer = csv.DictWriter(fout, fieldnames=GOLD_COLUMNS)
        writer.writeheader()

        for row in reader:
            gold_row = {
                "id": row["id"],
                "name": row["name"],
                "url": row["url"],
                "facebook_url": row.get("facebook_url", ""),
                "x_url": row.get("twitter_url", ""),
                "instagram_url": row.get("instagram_url", ""),
                "food_sharing_activities": semicolon_to_json_array(row.get("food_sharing_activities", "")),
                "how_it_is_shared": semicolon_to_json_array(row.get("how_it_is_shared", "")),
                "country": row["country"],
                "city": row["city"],
                "lng": row.get("lon", ""),
                "lat": row.get("lat", ""),
            }
            writer.writerow(gold_row)
            rows_written += 1

    print(f"Done: {rows_written} rows written to {OUTPUT}")


if __name__ == "__main__":
    main()
