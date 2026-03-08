"""Robust file reading utilities."""

from __future__ import annotations

from pathlib import Path

import pandas as pd


def read_csv_robust(path: str | Path, **kwargs) -> pd.DataFrame:
    """Read CSV with automatic encoding fallback.

    Tries utf-8, utf-8-sig, cp1252, latin1 in order.
    """
    for enc in ("utf-8", "utf-8-sig", "cp1252", "latin1"):
        try:
            return pd.read_csv(path, encoding=enc, **kwargs)
        except UnicodeDecodeError:
            continue
    return pd.read_csv(path, encoding="latin1", **kwargs)
