# Snowflake SQL Scripts

This folder contains SQL scripts for Snowflake data warehouse operations.

Internal logic reference:
- `docs/internal_snowflake_ingestion_runbook.md`

## Execution order

> **Note:** Scripts 00–03 are now managed by Terraform (`terraform/`).
> They are kept here as a reference for the original SQL definitions,
> but `terraform apply` is the source of truth for provisioning these objects.

| Order | File | Description | Managed by |
|-------|------|-------------|------------|
| 0 | `00_context.sql` | Session context setup (role, warehouse, database, schema) | Terraform |
| 1 | `01_file_formats.sql` | File format creation (JSON, CSV) | Terraform |
| 2 | `02_stages.sql` | External stage creation (Azure Blob Storage connection) | Terraform |
| 3 | `03_create_tables.sql` | Table creation | Terraform |
| 4 | `04_copy_into.sql` | Data loading (COPY INTO) | SQL (operational) |
| 5 | `05_dedup.sql` | Duplicate check views | SQL (operational) |
| 6 | `06_validation.sql` | Data validation queries | SQL (operational) |

## Template setup

Some scripts require credentials and are provided as templates.

### Template files

| Template | Create as | Purpose |
|----------|-----------|---------|
| `00_context.sql.template` | `00_context.sql` | Session context (role, warehouse, database) |
| `02_stages.sql.template` | `02_stages.sql` | External stage (Azure SAS token) |

### Setup steps

```bash
# 1. Copy templates
cp 00_context.sql.template 00_context.sql
cp 02_stages.sql.template 02_stages.sql

# 2. Fill in your Snowflake credentials in the copied files
# 3. Run scripts in order: 00 → 01 → 02 → ...
```

> **Note:** `.sql` files are listed in `.gitignore` to prevent credentials from being committed to the repository.

## Notes

- `04_copy_into.sql` uses explicit Azure folder paths (`data/exploration_data/...`, `data/gold/prod/...`).
- Tracker ingestion is included in step 4 as `COPY INTO raw_sharecity200_tracker_run01`.
- `ShareCity200Tracker.xlsx` cannot be loaded directly with `COPY INTO`; convert it to `data/bronze/run-01/ShareCity200Tracker.csv` first.
- `04_copy_into.sql` also snapshots Azure Bronze file inventory into `bronze_blob_inventory`.
