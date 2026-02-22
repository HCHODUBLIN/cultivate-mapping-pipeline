"""Public-safe ingestion configuration schema.

Only environment variable names and defaults are defined here.
No credentials are stored in this repository.
"""

from __future__ import annotations

from dataclasses import dataclass
import os


@dataclass(frozen=True)
class IngestionConfig:
    openai_api_key: str
    openai_model: str
    google_api_key: str
    google_cse_id: str


def load_config() -> IngestionConfig:
    return IngestionConfig(
        openai_api_key=os.getenv("OPENAI_API_KEY", ""),
        openai_model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        google_api_key=os.getenv("GOOGLE_API_KEY", ""),
        google_cse_id=os.getenv("GOOGLE_CSE_ID", ""),
    )
