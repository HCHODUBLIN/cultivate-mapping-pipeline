# dbt Models

This directory holds deterministic dbt models for the CULTIVATE medallion pipeline.

## Model layers

- `staging/`: Bronze snapshot source shaping
- `intermediate/`: Silver normalisation and entity-resolution steps
- `marts/`: Gold-ready analytical marts
- `analysis/`: Supporting analysis models

## Tests

Schema and data tests are defined in:
- `dbt/models/sources.yml`
- `dbt/models/staging/schema.yml`
- `dbt/models/marts/schema.yml`

## Commands

```bash
cd dbt
dbt deps
dbt run
dbt test
dbt docs generate
```

## Related docs

- Architecture decisions: `ARCHITECTURE.md`
- Conceptual data model: `schema/data_model.md`
- ERD source: `schema/ERD.dbml`
