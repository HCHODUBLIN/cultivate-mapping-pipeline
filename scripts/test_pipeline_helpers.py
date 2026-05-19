"""Unit tests for pipeline helper logic (no I/O).

Covers the deterministic helpers shared across the SHARECITY 100 scripts:
``is_alive`` (the alive-status rule) and ``parse_s3_url``.
"""

from __future__ import annotations

import pytest

from check_dead_links import is_alive, parse_s3_url


class TestIsAlive:
    @pytest.mark.parametrize("status", [200, 201, 204, 301, 302, 399, 403, 405, 406])
    def test_alive(self, status):
        assert is_alive(status) is True

    @pytest.mark.parametrize("status", [0, 400, 401, 404, 410, 429, 500, 503])
    def test_dead(self, status):
        assert is_alive(status) is False

    def test_boundaries(self):
        assert is_alive(200) is True
        assert is_alive(399) is True
        assert is_alive(400) is False
        assert is_alive(199) is False


class TestParseS3Url:
    def test_basic(self):
        assert parse_s3_url("s3://bucket/path/to/file.csv") == (
            "bucket", "path/to/file.csv",
        )

    def test_root_key(self):
        assert parse_s3_url("s3://bucket/file.csv") == ("bucket", "file.csv")

    def test_nested_prefix(self):
        assert parse_s3_url("s3://b/raw/sharecity100/2016/x.csv") == (
            "b", "raw/sharecity100/2016/x.csv",
        )

    @pytest.mark.parametrize("bad", [
        "https://bucket/file.csv",
        "/local/path.csv",
        "bucket/file.csv",
    ])
    def test_rejects_non_s3(self, bad):
        with pytest.raises(ValueError):
            parse_s3_url(bad)
