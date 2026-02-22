#!/usr/bin/env python3
"""Run ingestion classification for one or more URLs."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from ingestion.config import load_config
from ingestion.llm_classifier import LLMClassifier


def main() -> int:
    parser = argparse.ArgumentParser(description="Run ingestion classification entry point")
    parser.add_argument("--url", action="append", dest="urls", help="Source URL to classify (repeatable)")
    args = parser.parse_args()

    urls = args.urls or ["https://example.org"]
    cfg = load_config()
    classifier = LLMClassifier(model_version="v3.0.0", prompt_version="public-skeleton")

    print(f"model={cfg.openai_model} urls={len(urls)}")
    for url in urls:
        snap = classifier.classify(source_url=url)
        print(f"{snap.source_url}\t{snap.label}\t{snap.confidence}\t{snap.executed_at_utc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
