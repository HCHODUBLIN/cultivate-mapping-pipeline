# cultivate-mapping-pipeline

## Purpose of this repository

This repository documents the production automation pipeline that underpins the
**Food Sharing Map**, hosted on the **Sharing Solutions** platform
(https://www.sharingsolutions.eu/).

Although the pipeline was originally developed within the EU Horizon Europe
project **CULTIVATE**, it now operates as a production-grade system that supports
the continuous discovery, classification, and curation of urban food sharing
initiatives across cities.

## Scope and limitations

This repository provides a public, security-safe representation of the Food
Sharing Map and its associated analysis pipeline.

## Repository structure

This repository is organised to separate system-level documentation from
implementation artefacts and extended technical notes.

Core system documents are provided at the repository root to communicate
overall architecture, scale, and design intent. Additional implementation
detail, validation notes, and governance considerations are documented under
`docs/`.

Executable queries and scripts are grouped by function (`analysis/`,
`snowflake/`, `azure/`) and are provided in public-safe form.

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
