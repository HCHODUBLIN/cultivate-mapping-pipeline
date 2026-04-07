# CLAUDE.md

## Project Overview

CULTIVATE mapping pipeline — end-to-end data platform for discovering, classifying, and curating food sharing initiatives across 105 European cities.

### Goals

1. Make experiments reproducible
2. Work on SHARECITY 100 with updated LLM prompt and data quality script

## Architecture

```
S3 (raw data) → DuckDB → dbt (staging → intermediate → marts) → Dashboards
```

- **dbt** (`dbt/`): SQL transformations across staging/intermediate/marts layers (dbt-duckdb)
- **Scripts** (`scripts/`): Python utilities for data loading, normalisation, link checking
- **Evaluation** (`evaluation/`): Classification accuracy tracking (F1, precision, recall)
- **Exploration** (`exploration/`): Prompt engineering experiments, A/B testing

## Tech Stack

- **DuckDB**: Local analytical database (replaces Snowflake)
- **dbt**: Transformation framework with dbt-duckdb adapter (models in `dbt/models/`)
- **AWS S3**: Data storage (`cultivate-mapping-data` bucket, `eu-north-1`)
- **Python**: Ingestion scripts, analysis pipelines

## Key Conventions

- dbt profile at `~/.dbt/profiles.yml` (type: duckdb)
- dbt schemas: `staging`, `intermediate`, `marts`
- Branch: `feat/aws-migration` is the active working branch

## Working Style

1. Work only one file at a time
2. Don't change files before asking — guide the user, let them write
3. The user writes code themselves with Claude's guidance
4. Never add unused libraries, redundant files, or unnecessary lines of code

## Commits

- Commit and push at every meaningful change
- No Co-Authored-By lines
- Simple but trackable messages with proper tags (feat:, fix:, refactor:, docs:, chore:)

## Commands

```bash
# dbt
cd dbt && dbt run && dbt test

# Linting
pre-commit run --all-files
```

## Files to Never Commit

- `.env` (secrets)
- `*.duckdb` (local database)
