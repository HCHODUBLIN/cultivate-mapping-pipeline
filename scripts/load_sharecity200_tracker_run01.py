#!/usr/bin/env python3
"""Load ShareCity200Tracker.xlsx (run-01) into Snowflake raw table.

Usage:
  python scripts/load_sharecity200_tracker_run01.py \
    --xlsx /path/to/ShareCity200Tracker.xlsx

Snowflake auth is read from environment variables:
  SNOWFLAKE_ACCOUNT
  SNOWFLAKE_USER
  SNOWFLAKE_PASSWORD
  SNOWFLAKE_WAREHOUSE
  SNOWFLAKE_DATABASE
  SNOWFLAKE_SCHEMA
  SNOWFLAKE_ROLE (optional, defaults ACCOUNTADMIN)
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import argparse
import os
import re
import sys

import pandas as pd

try:
    import snowflake.connector
except ImportError:  # pragma: no cover
    snowflake = None  # type: ignore[assignment]


DEST_TABLE = "RAW_SHARECITY200_TRACKER_RUN01"

DEST_COLUMNS = [
    "region",
    "country",
    "city",
    "language",
    "sharecity_tier",
    "hub_or_spoke",
    "priority",
    "dcu_fsi_search_plan_week_commencing",
    "tcd_manual_check_plan_week_commencing",
    "data_entry_size_before_manual_checking",
    "manual_review_checker_assigned",
    "fsis_searched",
    "data_reviewed",
    "data_uploaded",
    "automation_tool_version",
    "comments",
    "valid_fsi",
    "accuracy_rate",
    "correct_name",
    "name_accuracy_rate",
    "file_name",
]

SOURCE_TO_DEST = {
    "region": "region",
    "country": "country",
    "city": "city",
    "language": "language",
    "sharecity100_or_200": "sharecity_tier",
    "hub_or_spoke": "hub_or_spoke",
    "priority": "priority",
    "dcu_fsi_search_plan_week_commencing": "dcu_fsi_search_plan_week_commencing",
    "tcd_manual_check_plan_week_commencing_2": "tcd_manual_check_plan_week_commencing",
    "data_entry_size_before_manual_checking": "data_entry_size_before_manual_checking",
    "manual_review_checker_assigned": "manual_review_checker_assigned",
    "fsis_searched": "fsis_searched",
    "data_reviewed": "data_reviewed",
    "data_uploaded": "data_uploaded",
    "automation_tool_version": "automation_tool_version",
    "comments": "comments",
    "valid_fsi": "valid_fsi",
    "accuracy_rate": "accuracy_rate",
    "correct_name": "correct_name",
    "name_accuracy_rate": "name_accuracy_rate",
}


@dataclass(frozen=True)
class SnowflakeAuth:
    account: str
    user: str
    password: str
    warehouse: str
    database: str
    schema: str
    role: str


def env(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def load_auth() -> SnowflakeAuth:
    return SnowflakeAuth(
        account=env("SNOWFLAKE_ACCOUNT"),
        user=env("SNOWFLAKE_USER"),
        password=env("SNOWFLAKE_PASSWORD"),
        warehouse=env("SNOWFLAKE_WAREHOUSE"),
        database=env("SNOWFLAKE_DATABASE"),
        schema=env("SNOWFLAKE_SCHEMA"),
        role=env("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )


def validate_auth(auth: SnowflakeAuth) -> list[str]:
    missing = []
    for field in ("account", "user", "password", "warehouse", "database", "schema"):
        if not getattr(auth, field):
            missing.append(field.upper())
    return missing


def normalize_header(name: str) -> str:
    out = str(name).strip().lower()
    out = out.replace("?", "")
    out = re.sub(r"[^a-z0-9]+", "_", out)
    out = re.sub(r"_+", "_", out).strip("_")
    return out


def load_xlsx(xlsx_path: Path, sheet_name: str | int = 0) -> pd.DataFrame:
    df = pd.read_excel(xlsx_path, sheet_name=sheet_name, engine="openpyxl")
    df.columns = [normalize_header(c) for c in df.columns]
    rename_map = {src: dest for src, dest in SOURCE_TO_DEST.items() if src in df.columns}
    df = df.rename(columns=rename_map)

    missing_required = [c for c in ("region", "country", "city") if c not in df.columns]
    if missing_required:
        raise ValueError(
            "Missing required columns after normalization: "
            + ", ".join(missing_required)
        )

    for col in DEST_COLUMNS:
        if col not in df.columns:
            df[col] = None

    df = df[DEST_COLUMNS[:-1]].copy()  # add file_name separately
    df["file_name"] = xlsx_path.name

    for col in df.columns:
        df[col] = df[col].apply(
            lambda v: None if pd.isna(v) else str(v).strip()
        )

    return df


def create_table_if_needed(cur) -> None:
    cur.execute(
        f"""
        create table if not exists {DEST_TABLE} (
          region string,
          country string,
          city string,
          language string,
          sharecity_tier string,
          hub_or_spoke string,
          priority string,
          dcu_fsi_search_plan_week_commencing string,
          tcd_manual_check_plan_week_commencing string,
          data_entry_size_before_manual_checking string,
          manual_review_checker_assigned string,
          fsis_searched string,
          data_reviewed string,
          data_uploaded string,
          automation_tool_version string,
          comments string,
          valid_fsi string,
          accuracy_rate string,
          correct_name string,
          name_accuracy_rate string,
          file_name string,
          loaded_at timestamp_ntz default current_timestamp()
        )
        """
    )


def insert_rows(cur, rows: list[tuple], truncate_first: bool) -> None:
    if truncate_first:
        cur.execute(f"truncate table identifier('{DEST_TABLE}')")

    placeholders = ", ".join(["%s"] * len(DEST_COLUMNS))
    cols = ", ".join(DEST_COLUMNS)
    insert_sql = (
        f"insert into identifier('{DEST_TABLE}') ({cols}) values ({placeholders})"
    )
    cur.executemany(insert_sql, rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xlsx", required=True, help="Path to ShareCity200Tracker.xlsx")
    parser.add_argument(
        "--sheet-name",
        default=0,
        help="Excel sheet name or zero-based index (default: 0)",
    )
    parser.add_argument(
        "--append",
        action="store_true",
        help="Append rows instead of truncating destination table first",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if snowflake is None:
        print(
            "Missing dependency: snowflake-connector-python\n"
            "Install with: pip install snowflake-connector-python",
            file=sys.stderr,
        )
        return 1

    xlsx_path = Path(args.xlsx).expanduser().resolve()
    if not xlsx_path.exists():
        print(f"XLSX file not found: {xlsx_path}", file=sys.stderr)
        return 1

    auth = load_auth()
    missing = validate_auth(auth)
    if missing:
        print(
            "Missing env vars for Snowflake auth: "
            + ", ".join(f"SNOWFLAKE_{m}" for m in missing),
            file=sys.stderr,
        )
        return 1

    sheet_name: str | int = args.sheet_name
    if isinstance(sheet_name, str) and sheet_name.isdigit():
        sheet_name = int(sheet_name)

    df = load_xlsx(xlsx_path, sheet_name=sheet_name)
    rows = list(df.itertuples(index=False, name=None))

    conn = snowflake.connector.connect(
        account=auth.account,
        user=auth.user,
        password=auth.password,
        warehouse=auth.warehouse,
        database=auth.database,
        schema=auth.schema,
        role=auth.role,
    )
    try:
        with conn.cursor() as cur:
            create_table_if_needed(cur)
            insert_rows(cur, rows, truncate_first=not args.append)
            cur.execute(f"select count(*) from {DEST_TABLE}")
            total = cur.fetchone()[0]
            print(f"Loaded {len(rows)} rows into {DEST_TABLE}. Current total rows: {total}")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
