# Ingestion - LLM Classification Pipeline (Landing Layer)

This module handles URL discovery and LLM-based classification.
It sits **outside the medallion** because LLM outputs are non-deterministic.

## Architecture versions

- v1.x-v2.x: Crawl-and-store (scrape -> store -> classify)
- v3.x: Agent-based (retrieve and classify in single operation)

## Outputs

LLM results are snapshotted into Bronze with metadata:
- model version
- prompt version
- execution timestamp
- confidence score

## Configuration

Copy `.env.example` to `.env` and fill in API credentials.
See `config.py` for all configuration parameters.

## Prompts

The `prompts/` directory contains prompt design patterns and versioning
documentation only. Full prompt text is published in:
Cho, H. et al. (2026) Appendix E (v2.0.0) and Appendix F (v3.0.0).

Prompt full text is not included in this repository.
Included here: template structure, variable schema, and versioning convention.
