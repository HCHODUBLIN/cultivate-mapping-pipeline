# cultivate-mapping-pipeline

**Start here:**
Architecture overview → [ARCHITECTURE.md](ARCHITECTURE.md) | Data model → [schema/](schema/) | Exploration & experiments → [exploration/](exploration/) | Design rationale → [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md)

---

## Purpose of this repository

This repository documents the production-grade data automation pipeline that underpins the **Food Sharing Map**, hosted on the **Sharing Solutions** platform  
(https://www.sharingsolutions.eu/).

Although the pipeline was originally developed within the EU Horizon Europe project **CULTIVATE**, it now operates as a production system supporting the continuous discovery, classification, and curation of urban food sharing initiatives across cities.

This repository provides a **public, security-safe representation** of that system, focusing on architecture, data models, validation logic, and analytical evaluation workflows.

---

## Key achievements

### Data pipeline impact

- Automated discovery and classification across **105 European cities**
- Processes **~210,000 URLs per iteration** (~3GB unstructured text)
- Improved classification accuracy from **32% → 74%** (manual validation benchmark)

### Technical stack

- **Snowflake** data warehouse with dbt transformations
- **Azure Blob Storage** integration for scalable data ingestion
- **Python** analysis pipelines with LLM-based classification  
  (GPT-4o used in offline evaluation and optimisation experiments)
- **Bronze / Silver / Gold** medallion architecture for data quality and reuse

### Data architecture and quality

- **Entity Relationship Diagram** documenting the full data model  
  ([interactive ERD](schema/ERD.dbml))
- **Comprehensive dbt tests** enforcing integrity across all layers
- **URL normalisation** used as Master Data Management (MDM) for entity resolution
- **Multi-strategy deduplication**:
  - exact matching
  - URL-based matching
  - fuzzy matching (92% similarity threshold)
- **88 duplicates removed** (3,140 → 3,052 initiatives; 2.8% deduplication rate)

### Research and optimisation

- Designed and executed A/B testing for prompt and rule variations  
  ([exploration/legacy_2025/02](exploration/legacy_2025/02))
- Reduced false positives through systematic exclusion rule refinement
- Automated validation and deduplication workflows aligned with manual review

---

## Scope and limitations

> **Note**  
> This repository is a portfolio reference, not a runnable application.

It documents the architecture, data models, and analytical workflows of a production system. Running the full pipeline requires access to private Snowflake and Azure environments, proprietary automation tools, and partner-only datasets, which are **not included** here.

All sensitive components have been removed or abstracted to provide a public, security-safe representation.

Raw project data is governed within the official CULTIVATE SharePoint environment. This repository documents the architecture and analytical workflows only; it does not store or replicate project data. This repository represents my individual technical contributions within a collaborative project and does not claim ownership of project assets. For the internal team version, please refer to [cultivate-team-pipeline](https://github.com/HCHODUBLIN/cultivate-team-pipeline).

---

## Repository structure

This repository showcases both **production data engineering** and **analytical research** work.

### Production pipeline

- **`snowflake/`**  
  Production SQL scripts for warehouse operations
- **`models/`**  
  dbt transformation models (staging → intermediate → marts)
  - Data quality tests defined in `schema.yml` files
  - See [models/README.md](models/README.md) for details
- **`infra/`**  
  Infrastructure and DevOps utilities
  - `infrastructure/azure/` — Azure Blob Storage sync and CLI setup
- **`schema/`**  
  Data model documentation
  - [data_model.md](schema/data_model.md) — conceptual and physical model
  - [ERD.dbml](schema/ERD.dbml), [ERD.md](schema/ERD.md) — ERD definitions
- **`governance/`**  
  Security policy and collaboration roles

### Research and analysis

- **`exploration/`**  
  Experimental and optimisation work ([see overview](exploration/README.md))
  - Agent-based classification architecture (+42% accuracy improvement)
  - Prompt engineering and systematic A/B testing
  - Manual verification workflows and deduplication analysis

### Data organisation

- **`data/`**  
  Bronze / Silver / Gold datasets (not tracked in git)
- **`reports/`**  
  Generated analysis outputs and visualisations (not tracked in git)

Core system documents at the repository root explain overall architecture, scale, and key design decisions. Executable queries and scripts are provided in public-safe form and grouped by function.

---

## Production environment

The production pipeline runs on the following stack. These services are **not included** in this repository.

| Component              | Purpose                                          |
| ---------------------- | ------------------------------------------------ |
| **Snowflake**          | Data warehouse (Bronze / Silver / Gold tables)   |
| **dbt**                | SQL transformations and data quality tests       |
| **Azure Blob Storage** | Raw data ingestion and file synchronisation      |
| **OpenAI API**         | LLM-based classification (GPT-4o in experiments) |

---

## Data quality testing

dbt tests enforce integrity across all layers, including:

- **Uniqueness** — primary keys across tables
- **Not null** — critical fields (city, URL, identifiers)
- **Relationships** — foreign key integrity
- **Accepted values** — categorical fields (e.g. round_version, cluster)
- **Accepted ranges** — numeric metrics (e.g. percentages, counts)
- **Custom tests** — total count checks  
  (3,140 Bronze records; 3,052 Gold records)

See [models/README.md](models/README.md) for full documentation.

---

## Included and excluded components

### Not included

- Automation tool source code
- Credentials (SAS tokens, API keys, secrets)
- Partner-only or internal datasets
- Proprietary prompts, models, or classifiers

### Included

- Dataset schemas and data contracts
- Public-safe Snowflake SQL scripts
- Validation and quality assurance logic
- Example configurations and synthetic samples
- Analysis pipelines for recall and precision evaluation
- Multi-level URL matching with similarity scoring

---

## Contributions and collaboration

This work was developed within **WP2 of the CULTIVATE project** (EU Horizon Europe) through collaboration between **Trinity College Dublin (TCD)** and **Dublin City University (DCU)**.

The author, **Dr Hyunji Cho**, served as **Data Solution Architect and Systems Design Lead** for Sharing Solutions, with responsibility for:

- design and implementation of the mapping and analysis pipeline;
- data modelling and schema definition;
- cloud-based ingestion and validation workflows; and
- development of public-safe analytical queries and evaluation methods.

| Role                                             | Organisation           |
| ------------------------------------------------ | ---------------------- |
| WP2 academic leadership                          | Trinity College Dublin |
| Automation tool development                      | DCU / ADAPT Centre     |
| Pipeline design, modelling, validation, analysis | TCD WP2 technical team |

---

## References

Live map: https://www.sharingsolutions.eu/  
Project website: https://cultivate-project.eu/

### Academic output

Wu, H., Cho, H., Davies, A. R., & Jones, G. J. F. (2024).  
_LLM-based Automated Web Retrieval and Text Classification of Food Sharing Initiatives_.  
Proceedings of the 33rd ACM International Conference on Information and Knowledge Management (CIKM ’24).  
DOI: 10.1145/3627673.3680090
