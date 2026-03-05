"""Shared Snowflake authentication utilities."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class SnowflakeAuth:
    account: str
    user: str
    password: str
    warehouse: str
    database: str
    schema: str
    role: str = ""


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
