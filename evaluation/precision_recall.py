"""Precision and recall helpers for fixed reference-set evaluation."""

from __future__ import annotations


def precision(true_positive: int, false_positive: int) -> float:
    denom = true_positive + false_positive
    if denom == 0:
        return 0.0
    return true_positive / denom


def recall(true_positive: int, false_negative: int) -> float:
    denom = true_positive + false_negative
    if denom == 0:
        return 0.0
    return true_positive / denom
