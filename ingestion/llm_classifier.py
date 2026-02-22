"""Shared LLM classification interfaces for ingestion snapshots.

This module intentionally exposes only public-safe structure.
Implementation-specific business rules and secrets are not stored here.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any


@dataclass(frozen=True)
class ClassificationSnapshot:
    source_url: str
    label: str
    confidence: float
    model_version: str
    prompt_version: str
    executed_at_utc: str


class LLMClassifier:
    """Minimal classifier interface used by ingestion runners."""

    def __init__(self, model_version: str, prompt_version: str) -> None:
        self.model_version = model_version
        self.prompt_version = prompt_version

    def classify(self, source_url: str, context: dict[str, Any] | None = None) -> ClassificationSnapshot:
        """Return a deterministic schema for a non-deterministic LLM decision.

        Replace this placeholder with production API invocation logic.
        """
        _ = context
        return ClassificationSnapshot(
            source_url=source_url,
            label="unknown",
            confidence=0.0,
            model_version=self.model_version,
            prompt_version=self.prompt_version,
            executed_at_utc=datetime.now(timezone.utc).isoformat(),
        )
