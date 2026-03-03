"""Shared URL normalization utilities.

Canonical implementation that matches the dbt SQL logic in
``dbt/models/staging/stg_automation.sql`` and ``stg_ground_truth.sql``.

All Python code that needs URL normalization should import from here
instead of re-implementing the logic.
"""

from __future__ import annotations

import re
import unicodedata


def normalize_url(url: object) -> str:
    """Normalize a URL for deduplication and matching.

    Normalization steps (mirroring dbt SQL):
      1. Strip leading/trailing whitespace
      2. Unicode NFKC normalization
      3. Remove ``http://`` or ``https://`` and optional ``www.``
      4. Remove query parameters (``?…``) and fragments (``#…``)
      5. Remove trailing slashes
      6. Remove trailing single-quotes (data-quality artefact)
      7. Collapse internal whitespace
      8. Case-fold to lowercase

    Returns an empty string for *None*, *NaN*, or blank inputs.
    """
    if url is None:
        return ""

    # Handle pandas NaN / numpy NaN without importing pandas
    try:
        if url != url:  # NaN != NaN
            return ""
    except (TypeError, ValueError):
        pass

    s = str(url).strip()
    if not s:
        return ""

    s = unicodedata.normalize("NFKC", s)
    s = re.sub(r"^https?://", "", s, flags=re.IGNORECASE)
    s = re.sub(r"^www\.", "", s, flags=re.IGNORECASE)
    s = re.sub(r"[?#].*$", "", s)
    s = re.sub(r"/+$", "", s)
    s = re.sub(r"'+$", "", s)
    s = re.sub(r"\s+", "", s)
    return s.casefold()


def extract_domain(url: object) -> str:
    """Extract the bare domain from a URL.

    Examples::

        >>> extract_domain("https://www.example.com/path?q=1")
        'example.com'
        >>> extract_domain("example.com/path")
        'example.com'

    Returns an empty string for *None*, *NaN*, or blank inputs.
    """
    if url is None:
        return ""

    try:
        if url != url:
            return ""
    except (TypeError, ValueError):
        pass

    s = str(url).strip()
    if not s:
        return ""

    s = unicodedata.normalize("NFKC", s)
    s = re.sub(r"^https?://", "", s, flags=re.IGNORECASE)
    s = re.sub(r"^www\.", "", s, flags=re.IGNORECASE)
    s = re.sub(r"/.*$", "", s)
    return s.casefold()
