"""Accuracy tracking utilities for pipeline version comparisons."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class AccuracyRecord:
    version: str
    correct: int
    total: int

    @property
    def accuracy(self) -> float:
        if self.total == 0:
            return 0.0
        return self.correct / self.total
