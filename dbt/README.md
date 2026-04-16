# dbt — Deterministic Medallion Transformations

SQL transformations over three datasets: **metadata** (shared lookups),
**cultivate100** (production FSI mapping), **sharecity100** (2016 + 2024
re-validation). All models read from S3 via dbt-duckdb `httpfs`; the
DuckDB file is a local cache and is not committed.

## Run

```bash
cd dbt
dbt deps
dbt build        # run + test; or: dbt run / dbt test
```

A single schema per domain lives in the DuckDB database:

| Schema | Models |
|---|---|
| `metadata` | `stg_city_list` |
| `cultivate100` | `stg_automation_run01..04`, `stg_verified_run01..04` |
| `sharecity100` | `stg_manual_2016`, `stg_deadlink_{2016,2024}`, `stg_scraped_2024`, `int_alive_urls_2016`, `int_alive_2016_enriched`, `int_2016_cultivate_normalized` |

## Project layout

```
dbt/
├── dbt_project.yml
├── macros/
│   └── normalize_city.sql          -- accent/punctuation-agnostic city key
└── models/
    ├── sources.yml                 -- all S3-backed sources
    ├── metadata/                   -- cross-dataset reference tables
    ├── cultivate100/               -- production FSI mapping
    │   ├── staging/
    │   ├── intermediate/
    │   └── marts/
    └── sharecity100/               -- 2016 + 2024 re-validation pipeline
        ├── staging/
        ├── intermediate/
        └── marts/
```

## Pipeline (high level)

Each domain reads its own S3 prefix and keeps work isolated. `metadata`
is shared — it feeds both CULTIVATE 100 and SHARECITY 100 where a
city lookup is needed.

```mermaid
flowchart LR
    subgraph S3[s3://cultivate-mapping-data/raw]
      S3A[automation/run-01..04]
      S3V[manual_verified/run-01..04]
      S3M[metadata/*.csv]
      S316[sharecity100/2016/*.csv]
      S324[sharecity100/2024/*.csv]
    end

    S3M  --> META[metadata schema]
    S3A  --> C100[cultivate100 schema]
    S3V  --> C100
    S316 --> SC100[sharecity100 schema]
    S324 --> SC100

    META --- SC100
    META --- C100

    SC100 --> MARTS[[Gold marts]]
    C100  --> MARTS
```

## SHARECITY 100 model lineage

The active work — re-validate 2016 entries against 2024 automation output,
with a final schema aligned to CULTIVATE 100 for cross-dataset analysis.

```mermaid
flowchart LR
    src_man[(manual_2016<br/>source)]
    src_dl16[(deadlink_2016<br/>source)]
    src_dl24[(deadlink_2024<br/>source)]
    src_sc24[(scraped_2024<br/>source)]
    src_cl[(metadata.city_list<br/>source)]

    src_man --> stg_man[stg_manual_2016<br/>+ city_key]
    src_dl16 --> stg_dl16[stg_deadlink_2016]
    src_dl24 --> stg_dl24[stg_deadlink_2024]
    src_sc24 --> stg_sc24[stg_scraped_2024]
    src_cl  --> stg_cl[stg_city_list<br/>+ city_key]

    stg_dl16 --> int_alive[int_alive_urls_2016<br/>alive = true]
    int_alive --> int_enr[int_alive_2016_enriched<br/>+ manual cols]
    stg_man  --> int_enr

    int_enr --> int_norm[int_2016_cultivate_normalized<br/>CULTIVATE 100 schema]
    stg_cl  --> int_norm

    classDef src fill:#eee,stroke:#999,stroke-dasharray: 4 2
    classDef stg fill:#e8f1ff,stroke:#4a7ab8
    classDef int fill:#ffe8c8,stroke:#b8884a
    class src_man,src_dl16,src_dl24,src_sc24,src_cl src
    class stg_man,stg_dl16,stg_dl24,stg_sc24,stg_cl stg
    class int_alive,int_enr,int_norm int
```

## Reproducibility

All transforms are deterministic given fixed S3 inputs.
- `macros/normalize_city.sql` provides the single source of truth for
  the city join key (accents, punctuation, state suffix are stripped).
- `dbt build` is the one-shot entry point: models build, tests run,
  and downstream models skip when upstream tests fail.
