"""F1 score helper."""

from __future__ import annotations


def f1_score(precision_value: float, recall_value: float) -> float:
    denom = precision_value + recall_value
    if denom == 0:
        return 0.0
    return 2 * (precision_value * recall_value) / denom
