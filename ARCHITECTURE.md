# ARCHITECTURE

This document records key design decisions for the CULTIVATE end-to-end mapping pipeline.

## Terminology

This repository follows industry-standard medallion naming (Bronze/Silver/Gold).
In published work (Cho et al. 2026), we use candidate/assessed/validated
for cross-disciplinary readability with non-technical collaborators.

| Repository (this repo) | Published work (paper) | dbt directory |
|------------------------|------------------------|---------------|
| Landing | - | `ingestion/` |
| Bronze | Candidate | `dbt/models/staging/` |
| Silver | Assessed | `dbt/models/intermediate/` |
| Gold | Validated | `dbt/models/marts/` |

**Why two naming systems?**
The team includes social scientists alongside data engineers. Standard
medallion terminology communicates little about data status to non-technical
collaborators in research communication. In published work, layers are framed
by epistemic meaning (candidate/assessed/validated). In this engineering
repository, standard medallion terms are used because that is industry norm.

Same architecture, different framing for different audiences.

## Why LLM classification sits outside the medallion

dbt + Snowflake medallion assumes deterministic transformations: `dbt run`
produces the same output from the same input. LLM classification breaks this
principle. The same URL can yield different results depending on:

- Model version
- Prompt version
- Web page state at time of access
- Non-deterministic model behaviour

Therefore, LLM outputs are treated as an external source, not a transformation
step. Results are snapshotted into Bronze with metadata (model version, prompt
version, execution timestamp, confidence score) and treated as immutable records.

This keeps the dbt layer reproducible while preserving LLM results as
auditable snapshots.

## Architecture evolution

| Version | Architecture | How web evidence is accessed | Accuracy |
|---------|--------------|------------------------------|----------|
| v1.0.0 | Crawl-and-store | Scrape -> store -> classify from stored text | 32.0% |
| v2.0.0 | Crawl-and-store + 2nd stage filter | Same + additional filtering pass | 68.9% |
| v3.0.0 | Agent-based | Retrieve and classify in single operation | 74.5% |

Key trade-off in v3.0.0: raw scraped text is no longer stored. This means
Bronze snapshots cannot be re-derived from Landing URLs. This is a
deliberate decision because web pages change over time, and even re-scraping
would not produce identical content. The LLM snapshot is the source of truth.

## Evaluation: monitoring, not transformation

| | dbt tests (inside pipeline) | `evaluation/` (outside pipeline) |
|---|---|---|
| Role | "Is this column not null?" | "What's this LLM version's F1?" |
| Runs | During `dbt test` | Separately via `scripts/run_evaluation.py` |
| On failure | Pipeline stops | Report generated, pipeline continues |
| Scope | Silver data quality | Bronze (LLM output) performance |

F1, precision, and recall are computed by comparing Bronze snapshots against
a fixed reference set (228 URLs, 73 confirmed). These metrics do not enter
the transformation pipeline; they track pipeline performance over time.

Version-level results are recorded in `evaluation/reports/`.
