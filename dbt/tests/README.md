# dbt Tests

This directory is reserved for dbt data tests that are not declared inline in `schema.yml`.

Current integrity checks are primarily defined in:
- `dbt/models/staging/schema.yml`
- `dbt/models/marts/schema.yml`
- `dbt/models/sources.yml`

Reverse-engineering parity checks (rebuilt vs reference Gold):
- `test_gold_rebuild_count_match.sql`
- `test_gold_rebuild_key_set_match.sql`
- `test_gold_rebuild_row_hash_match.sql`
