#!/usr/bin/env python3
"""Run Snowflake load SQL files and print row counts for key tables.

This script executes the repository SQL flow in order:
00_context.sql -> 01_file_formats.sql -> 02_stages.sql (optional) ->
03_create_tables.sql -> 04_copy_into.sql -> 06_validation.sql
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import os
import re
import sys

try:
    import snowflake.connector
except ImportError:  # pragma: no cover
    snowflake = None  # type: ignore[assignment]


ROOT = Path(__file__).resolve().parents[1]
SNOWFLAKE_DIR = ROOT / "snowflake"


@dataclass(frozen=True)
class SnowflakeAuth:
    account: str
    user: str
    password: str
    warehouse: str
    database: str
    schema: str


def env(name: str) -> str:
    return os.getenv(name, "").strip()


def load_auth() -> SnowflakeAuth:
    return SnowflakeAuth(
        account=env("SNOWFLAKE_ACCOUNT"),
        user=env("SNOWFLAKE_USER"),
        password=env("SNOWFLAKE_PASSWORD"),
        warehouse=env("SNOWFLAKE_WAREHOUSE"),
        database=env("SNOWFLAKE_DATABASE"),
        schema=env("SNOWFLAKE_SCHEMA"),
    )


def validate_auth(auth: SnowflakeAuth) -> list[str]:
    missing = []
    for field in ("account", "user", "password", "warehouse", "database", "schema"):
        if not getattr(auth, field):
            missing.append(field.upper())
    return missing


def split_sql_statements(sql_text: str) -> list[str]:
    statements = []
    for raw in sql_text.split(";"):
        cleaned = re.sub(r"--.*?$", "", raw, flags=re.MULTILINE).strip()
        if cleaned:
            statements.append(cleaned)
    return statements


def execute_sql_file(cur, path: Path) -> None:
    if not path.exists():
        print(f"[skip] {path.name} not found")
        return
    print(f"[exec] {path.name}")
    sql_text = path.read_text(encoding="utf-8")
    for stmt in split_sql_statements(sql_text):
        cur.execute(stmt)


def main() -> int:
    if snowflake is None:
        print(
            "Missing dependency: snowflake-connector-python\n"
            "Install with: pip install snowflake-connector-python",
            file=sys.stderr,
        )
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

    sql_flow = [
        SNOWFLAKE_DIR / "00_context.sql",
        SNOWFLAKE_DIR / "01_file_formats.sql",
        SNOWFLAKE_DIR / "02_stages.sql",
        SNOWFLAKE_DIR / "03_create_tables.sql",
        SNOWFLAKE_DIR / "04_copy_into.sql",
        SNOWFLAKE_DIR / "06_validation.sql",
    ]

    conn = snowflake.connector.connect(
        account=auth.account,
        user=auth.user,
        password=auth.password,
        warehouse=auth.warehouse,
        database=auth.database,
        schema=auth.schema,
    )
    try:
        with conn.cursor() as cur:
            for sql_file in sql_flow:
                execute_sql_file(cur, sql_file)

            print("\n[row counts]")
            tables = [
                "raw_ground_truth",
                "raw_automation",
                "raw_automation_reviewed",
                "raw_city_language",
                "raw_sharecity200_tracker_run01",
                "bronze_blob_inventory_raw",
                "silver_fsi_201225",
                "gold_fsi_200226",
            ]
            for table in tables:
                cur.execute(f"select count(*) from identifier('{table}')")
                count = cur.fetchone()[0]
                print(f"{table:28s} {count}")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
