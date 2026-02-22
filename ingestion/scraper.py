"""Legacy URL-to-text scraper interface for v1/v2 compatibility.

v3 agent-based runs may bypass this module.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ScrapeResult:
    source_url: str
    text: str
    status: str


def scrape_url(source_url: str) -> ScrapeResult:
    """Public-safe placeholder for legacy scraping logic."""
    return ScrapeResult(source_url=source_url, text="", status="not_implemented")
