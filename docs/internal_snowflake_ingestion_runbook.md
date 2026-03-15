# Internal Runbook: Snowflake Ingestion Logic

Purpose: preserve the agreed operational logic for Azure -> Snowflake ingestion and dbt staging dependencies.

## Scope

This runbook covers the SQL flow in `snowflake/`:

1. `00_context.sql`
2. `01_file_formats.sql`
3. `02_stages.sql`
4. `03_create_tables.sql`
5. `04_copy_into.sql`
6. `05_dedup.sql`
7. `06_validation.sql`

`07_publish_for_bi.sql` is intentionally removed and not part of the current pipeline.

## Core Rules

1. Azure ingestion must be managed in `snowflake/` SQL files.
2. `COPY INTO` paths must use explicit Azure subpaths (no ambiguous stage-root assumptions).
3. The tracker dataset is part of standard ingestion:
   `BRONZE_TRACKER_RUN01`.
4. `.xlsx` files are not ingested directly by Snowflake `COPY INTO`.
   Convert tracker to CSV first:
   `data/bronze/run-01/ShareCity200Tracker.csv`.
5. Bronze blob inventory must be snapshotted into
   `BRONZE_BLOB_INVENTORY` via `LIST @stg_azure_raw` + `RESULT_SCAN`.
   Use saved query id + positional columns (`$1..$4`) to avoid
   identifier-case errors in result-scan metadata.

## Current Source Paths (authoritative)

Used by `snowflake/04_copy_into.sql`:

- `data/exploration_data/legacy_2024_data/automation.csv`
- `data/exploration_data/legacy_2024_data/automation_reviewed.csv`
- `data/exploration_data/legacy_2024_data/city_language.csv`
- `data/exploration_data/legacy_2024_data/ground_truth.csv`
- `data/gold/prod/2026-02-17/sharecity200-export-1771342197988.csv`
- `data/bronze/run-01/ShareCity200Tracker.csv` (required for tracker step)

If Azure folder structure changes, update `04_copy_into.sql` first.

## Required Raw Tables

Created by `snowflake/03_create_tables.sql`:

- `BRONZE_AUTOMATION`
- `BRONZE_AUTOMATION_REVIEWED`
- `BRONZE_CITY_LANGUAGE`
- `BRONZE_GROUND_TRUTH`
- `BRONZE_TRACKER_RUN01`
- `BRONZE_BLOB_INVENTORY`

## dbt Dependency Notes

dbt source definitions depend on these tables:

- `BRONZE_BLOB_INVENTORY` -> `stg_bronze_blob_inventory`
- `BRONZE_TRACKER_RUN01` -> `stg_sharecity200_tracker_run01`

If table names or schemas change in Snowflake SQL, update:

- `dbt/models/sources.yml`
- related staging models in `dbt/models/staging/`

## Secrets / Safety

- Keep SAS token only in local `02_stages.sql` (from template).
- Never commit real token/account secrets.
- Keep credentials in local env/profile files only.

## Change Control

When changing ingestion logic:

1. Update SQL in `snowflake/`.
2. Update this runbook.
3. Update dbt `sources.yml` and impacted staging models.
4. Run `06_validation.sql` and confirm row counts.
