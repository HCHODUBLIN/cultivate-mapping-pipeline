#!/usr/bin/env python3
"""Run fixed reference-set evaluation summary."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

def main() -> int:
    reference_path = ROOT / "evaluation" / "reference_set.json"
    reports_dir = ROOT / "evaluation" / "reports"

    with reference_path.open("r", encoding="utf-8") as fh:
        ref = json.load(fh)

    print(
        "reference_set="
        f"{ref.get('candidate_url_count', 'unknown')} urls, "
        f"{ref.get('confirmed_initiative_count', 'unknown')} confirmed"
    )

    records = [
        ("v1.0.0", 32.0),
        ("v2.0.0", 68.9),
        ("v3.0.0", 74.5),
    ]
    for version, accuracy_pct in records:
        print(f"{version}\t{accuracy_pct:.1f}%")

    if reports_dir.exists():
        print("reports:")
        for path in sorted(reports_dir.glob("*_metrics.md")):
            print(f"- {path.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
