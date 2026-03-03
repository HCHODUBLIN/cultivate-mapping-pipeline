"""Unit tests for utils.normalize — URL normalization and domain extraction.

These tests verify that the Python implementation matches the dbt SQL logic
in ``stg_automation.sql`` / ``stg_ground_truth.sql``.
"""

from __future__ import annotations

import math

import pytest

from utils.normalize import extract_domain, normalize_url


# ---------------------------------------------------------------------------
# normalize_url
# ---------------------------------------------------------------------------

class TestNormalizeUrl:
    """Core normalization behaviour."""

    def test_strips_https(self) -> None:
        assert normalize_url("https://example.com/path") == "example.com/path"

    def test_strips_http(self) -> None:
        assert normalize_url("http://example.com/path") == "example.com/path"

    def test_strips_www(self) -> None:
        assert normalize_url("https://www.example.com/path") == "example.com/path"

    def test_strips_http_www(self) -> None:
        assert normalize_url("http://www.example.com") == "example.com"

    def test_removes_query_params(self) -> None:
        assert normalize_url("https://example.com/page?ref=abc&lang=en") == "example.com/page"

    def test_removes_fragment(self) -> None:
        assert normalize_url("https://example.com/page#section") == "example.com/page"

    def test_removes_query_and_fragment(self) -> None:
        assert normalize_url("https://example.com/page?q=1#top") == "example.com/page"

    def test_removes_trailing_slashes(self) -> None:
        assert normalize_url("https://example.com/path///") == "example.com/path"

    def test_removes_trailing_single_quotes(self) -> None:
        assert normalize_url("https://example.com/path'''") == "example.com/path"

    def test_removes_whitespace(self) -> None:
        assert normalize_url("  https://example.com / path  ") == "example.com/path"

    def test_lowercases(self) -> None:
        assert normalize_url("HTTPS://WWW.EXAMPLE.COM/PATH") == "example.com/path"

    def test_unicode_normalization(self) -> None:
        # Full-width 'Ａ' (U+FF21) should NFKC-normalize to 'a' after casefold
        assert normalize_url("https://example.com/\uff21\uff22\uff23") == "example.com/abc"

    def test_combined(self) -> None:
        url = "  HTTP://www.Food-Share.ie/about?lang=en#team  "
        assert normalize_url(url) == "food-share.ie/about"

    def test_bare_domain(self) -> None:
        assert normalize_url("example.com") == "example.com"

    def test_path_with_no_protocol(self) -> None:
        assert normalize_url("www.example.com/path/to/page") == "example.com/path/to/page"


class TestNormalizeUrlEdgeCases:
    """Null, NaN, and empty-string handling."""

    def test_none_returns_empty(self) -> None:
        assert normalize_url(None) == ""

    def test_nan_returns_empty(self) -> None:
        assert normalize_url(float("nan")) == ""

    def test_math_nan_returns_empty(self) -> None:
        assert normalize_url(math.nan) == ""

    def test_empty_string(self) -> None:
        assert normalize_url("") == ""

    def test_whitespace_only(self) -> None:
        assert normalize_url("   ") == ""

    def test_numeric_input(self) -> None:
        assert normalize_url(12345) == "12345"


# ---------------------------------------------------------------------------
# extract_domain
# ---------------------------------------------------------------------------

class TestExtractDomain:
    """Domain extraction behaviour."""

    def test_full_url(self) -> None:
        assert extract_domain("https://www.example.com/path/page") == "example.com"

    def test_url_with_port(self) -> None:
        assert extract_domain("https://example.com:8080/path") == "example.com:8080"

    def test_bare_domain(self) -> None:
        assert extract_domain("example.com") == "example.com"

    def test_bare_domain_with_path(self) -> None:
        assert extract_domain("example.com/some/path") == "example.com"

    def test_removes_www(self) -> None:
        assert extract_domain("https://www.food-share.ie/about") == "food-share.ie"

    def test_lowercases(self) -> None:
        assert extract_domain("HTTPS://WWW.EXAMPLE.COM/PATH") == "example.com"

    def test_none_returns_empty(self) -> None:
        assert extract_domain(None) == ""

    def test_nan_returns_empty(self) -> None:
        assert extract_domain(float("nan")) == ""

    def test_empty_string(self) -> None:
        assert extract_domain("") == ""


# ---------------------------------------------------------------------------
# Cross-check: normalize_url and extract_domain consistency
# ---------------------------------------------------------------------------

class TestCrossConsistency:
    """The domain of a normalized URL should match extract_domain of the original."""

    @pytest.mark.parametrize(
        "url",
        [
            "https://www.example.com/path?q=1",
            "http://food-share.ie/about#team",
            "HTTP://WWW.TEST.ORG/page///",
        ],
    )
    def test_domain_matches(self, url: str) -> None:
        norm = normalize_url(url)
        domain_from_norm = norm.split("/")[0]
        domain_direct = extract_domain(url)
        assert domain_from_norm == domain_direct
