# dbt - Deterministic Medallion Transformations

This directory contains deterministic SQL transformations for the CULTIVATE pipeline.

## Layout

- `models/staging/`: Bronze source shaping
- `models/intermediate/`: Silver normalisation and dedup preparation
- `models/marts/`: Gold-ready marts
- `tests/`: dbt-native tests and test documentation
- `dbt_project.yml`: dbt project configuration

## Run

```bash
cd dbt
dbt deps
dbt run
dbt test
```

The transformation logic is deterministic and reproducible from fixed snapshot inputs.
