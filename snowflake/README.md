# Snowflake SQL Scripts

This folder contains SQL scripts for Snowflake data warehouse operations.

## Execution order

| Order | File | Description |
|-------|------|-------------|
| 0 | `00_context.sql` | Session context setup (role, warehouse, database, schema) |
| 1 | `01_file_formats.sql` | File format creation (JSON, CSV) |
| 2 | `02_stages.sql` | External stage creation (Azure Blob Storage connection) |
| 3 | `03_create_tables.sql` | Table creation |
| 4 | `04_copy_into.sql` | Data loading (COPY INTO) |
| 5 | `05_dedup.sql` | Duplicate check views |
| 6 | `06_validation.sql` | Data validation queries |
| 7 | `07_powerbi_export.sql` | Power BI export MERGE |
| 8 | `08_silver_powerbi_export.sql` | Silver view (type casting) |

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

## CI/CD

For GitHub Actions Snowflake CI, credentials are injected via GitHub Secrets. See `.github/workflows/snowflake-ci.yml`.
