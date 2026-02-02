# cultivate-mapping-pipeline

## Purpose of this repository

This repository documents the production-grade data automation pipeline that underpins the **Food Sharing Map**, hosted on the **Sharing Solutions** platform
(https://www.sharingsolutions.eu/).

Although the pipeline was originally developed within the EU Horizon Europe
project **CULTIVATE**, it now operates as a production-grade system that supports
the continuous discovery, classification, and curation of urban food sharing
initiatives across cities.

## Key Achievements

**Data Pipeline Impact:**

- Automated discovery and classification across **105 European cities**
- Processes **~210,000 URLs** per iteration (~3GB unstructured text)
- Improved classification accuracy from **32% → 74%** (manual validation benchmark)

**Technical Stack:**

- **Snowflake** data warehouse with dbt transformations
- **Azure Blob Storage** integration for scalable data handling
- **Python** analysis pipeline with LLM-based classification (GPT-4o used in experiments)
- **Bronze/Silver/Gold** medallion architecture for data quality

**Data Architecture & Quality:**

- **Entity Relationship Diagram** ([interactive ERD](schema/ERD.dbml)) documenting full data model
- **Comprehensive dbt tests** ensuring data integrity across all layers
- **URL normalization** as Master Data Management (MDM) for entity resolution
- **Multi-strategy deduplication** (exact, URL-based, fuzzy matching with 92% similarity threshold)
- **88 duplicates removed** (3,140 → 3,052 FSIs, 2.8% deduplication rate)

**Research & Optimization:**

- Designed and executed A/B testing for prompt variations ([exploration/legacy_2025/02](exploration/legacy_2025/02))
- Reduced false positives through systematic exclusion rule refinement
- Automated data validation and deduplication workflows

---

## Scope and limitations

This repository provides a public, security-safe representation of the Food Sharing Map and its associated analysis pipeline, with all sensitive components removed or abstracted.

## Repository structure

This repository showcases both **production data engineering** and **analytical research** work:

### Production Pipeline

- **`snowflake/`** - Production SQL scripts for data warehouse operations
- **`models/`** - dbt transformation models (staging → intermediate → marts)
  - **Data Quality Tests** ([schema.yml files](models/)) - Comprehensive dbt tests for all layers
  - See [models/README.md](models/README.md) for detailed documentation
- **`infra/`** - Infrastructure and DevOps utilities
  - `infrastructure/azure/` - Azure Blob Storage sync and CLI setup
  - `release/` - Release management scripts
- **`schema/`** - Data model and ERD documentation
  - **Data Model** ([data_model.md](schema/data_model.md)) - Conceptual model and Snowflake implementation
  - **Entity Relationship Diagram** ([ERD.dbml](schema/ERD.dbml), [ERD.md](schema/ERD.md)) - Interactive data model visualization
- **`governance/`** - Security policy and collaboration roles

### Research & Analysis

- **`exploration/`** - Experimental work and optimization tests ([see details](exploration/README.md))
  - Agent-based architecture with **+42% accuracy improvement** (32% → 74%)
  - Prompt engineering experiments and systematic A/B testing
  - Manual verification workflows and deduplication analysis

### Data Organization

- **`data/`** - Bronze/Silver/Gold medallion architecture (not tracked in git)
- **`reports/`** - Generated analysis outputs and visualizations (not tracked in git)

Core system documents are provided at the repository root to communicate
overall architecture, scale, and design intent. Executable queries and scripts
are grouped by function and provided in public-safe form.

---

## Setup

### Environment Configuration

This project uses a `.env` file to manage sensitive credentials. **Never commit real credentials to git.**

1. Create your local `.env` file:

```bash
# Copy the template
cp .env.example .env

# Edit with your actual credentials
nano .env
```

2. Add your credentials to `.env`:
   - `AZURE_STORAGE_ACCOUNT_NAME` - Your Azure Storage account
   - `AZURE_STORAGE_KEY` - Your Azure access key
   - `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD` - Snowflake connection
   - `OPENAI_API_KEY` - OpenAI API key for classification

The `.env` file is gitignored. Only the template (`.env.example`) is tracked.

### Data Quality Testing

Run comprehensive data quality tests using dbt:

```bash
# Install dbt with Snowflake adapter
pip install dbt-snowflake

# Install dbt_utils for custom tests
dbt deps

# Run all tests
dbt test

# Run tests for specific layers
dbt test --select staging
dbt test --select marts

# Generate documentation with ERD
dbt docs generate
dbt docs serve  # View at http://localhost:8080
```

**Test Coverage:**

- **Uniqueness**: Primary keys across all tables
- **Not Null**: Critical fields (city, url, etc.)
- **Relationships**: Foreign key integrity
- **Accepted Values**: Categorical fields (round_version, fp_category, cluster)
- **Accepted Range**: Numeric metrics (0-100 for percentages, ≥0 for counts)
- **Custom Tests**: Total count checks (3,140 bronze, 3,052 gold)

See [models/README.md](models/README.md) for detailed testing documentation.

### Not included

- Automation tool source code
- Credentials (e.g. SAS tokens, keys, secrets)
- Partner-only or internal datasets
- Proprietary prompts, models, or classifiers

### Included

- Dataset schemas and data contracts
- Public-safe SQL scripts (Snowflake)
- Validation and quality assurance checks
- Example configurations and synthetic samples
- Analysis pipelines for recall and precision evaluation
- Multi-level URL matching with similarity scoring

## Contributions and roles

The author, Dr Hyunji Cho, contributed in a technical leadership role as
**Data Solution Architect and Systems Design Lead** for Sharing Solutions, with
responsibility for:

- design and implementation of the mapping and analysis pipeline;
- data modelling and schema definition;
- cloud-based data ingestion and validation workflows; and
- development of public-safe analytical queries.

The automation tool used for large-scale data collection and classification was
developed and maintained by **Dublin City University (DCU)** and the
**ADAPT Centre**.

## Analysis pipelines

This repository includes two complementary analysis approaches for evaluating
automation performance against manually curated ground truth data:

### 1. Domain-level matching (`08_analysis.sql`, `analysis_report.py`)

Quick statistical overview using domain-level URL matching. Provides:

- Recall metrics (ground truth coverage)
- Precision metrics (automation accuracy)
- Language and version comparison
- F1 scores

**Use when**: You need high-level performance metrics and aggregated statistics.

### 2. Similarity-based matching (`09_similarity_matching.sql`, `similarity_analysis.py`)

Multi-level URL matching with confidence scoring for manual review. Provides:

- Exact URL matches (100% confidence)
- Domain + path segment matches (75% confidence)
- Domain-only matches (20-40% confidence)
- String similarity percentages
- Manual review queue with prioritisation

**Use when**: You need to identify specific matches for manual validation, especially
for platforms like Facebook where domain-level matching is insufficient.

Both pipelines use dbt staging models with URL normalisation to ensure consistent
matching logic across SQL and Python implementations.

## Collaboration context

This work was developed within **WP2 of the CULTIVATE project** through close
collaboration between **Trinity College Dublin (TCD)** and
**Dublin City University (DCU)**.

- WP2 academic leadership: Trinity College Dublin
- Automation tool development: DCU / ADAPT Centre
- Mapping pipeline design, data modelling, validation, and analysis:
  TCD WP2 technical team

## References

Live map: https://www.sharingsolutions.eu/  
Project website: https://cultivate-project.eu/

### Academic outputs

The upstream automation tool (web retrieval, scraping, and LLM-based
classification) is described in:

Wu, H., Cho, H., Davies, A. R., & Jones, G. J. F. (2024).  
_LLM-based Automated Web Retrieval and Text Classification of Food Sharing
Initiatives_.  
In _Proceedings of the 33rd ACM International Conference on Information and
Knowledge Management (CIKM ’24)_.  
DOI: 10.1145/3627673.3680090
