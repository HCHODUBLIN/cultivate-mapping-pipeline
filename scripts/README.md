# scripts/

Python utilities and notebooks for the CULTIVATE mapping pipeline.

## SHARECITY 100 pipeline (priority-4 cities, run-01 data)

Sequential steps — each reads from the previous step's S3 output.

| # | Script | Purpose | Output (S3) |
|---|--------|---------|-------------|
| 1 | [check_dead_links.ipynb](check_dead_links.ipynb) | HEAD-check all 5888 candidate URLs, flag alive/dead | `04_SHARECITY100/dead_link_report.csv` |
| 2 | [scrape_text.ipynb](scrape_text.ipynb) | BeautifulSoup text extraction for alive URLs | `04_SHARECITY100/scraped_text.csv` |
| 3a | [classify_with_scraped_text.ipynb](classify_with_scraped_text.ipynb) | LLM classify (gpt-5-nano) using pre-scraped text | `04_SHARECITY100/llm_classification_scraped_text.csv` |
| 3b | [classify_with_web_search.ipynb](classify_with_web_search.ipynb) | LLM classify (gpt-5-nano) using OpenAI agents `WebSearchTool` | `04_SHARECITY100/llm_classification_web_search.csv` |

All SHARECITY 100 outputs live under
`s3://cultivate-mapping-data/raw/exploration_data/2026_data/04_SHARECITY100/`

3a vs 3b: 3a is cheaper/faster; 3b replicates the TypeScript agent that fetches content live. Run both to compare.

## Utilities

| Script | Purpose |
|--------|---------|
| [normalize.py](normalize.py) | URL normalisation helpers used across pipelines |
| [io.py](io.py) | S3 / local file I/O helpers |
| [auth_cache.py](auth_cache.py) | OAuth/token cache for external APIs |
| [test_normalize.py](test_normalize.py) | Unit tests for `normalize.py` |

## Legacy (Snowflake/Azure era — kept for reference)

| Script | Purpose |
|--------|---------|
| [azure_blob_sync.py](azure_blob_sync.py) | Sync Azure Blob to local — replaced by S3 |
| [run_snowflake_load.py](run_snowflake_load.py) | Load raw data into Snowflake — obsolete after DuckDB migration |
| [check_snowflake_sql.sh](check_snowflake_sql.sh) | Snowflake SQL smoke tests — obsolete |
| [run_dbt.sh](run_dbt.sh) | dbt run wrapper |
