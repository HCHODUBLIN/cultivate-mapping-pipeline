# cultivate-mapping-pipeline

# Public-safe documentation of the mapping and analysis pipeline developed in WP2 of the EU Horizon Europe project CULTIVATE.

## Purpose of this repository

This repository documents an end-to-end data pipeline for mapping and analysing
urban food sharing initiatives, developed as part of the CULTIVATE project.

It focuses on:

- The structure and schema of mapping outputs
- Cloud-based data storage and ingestion (Azure → Snowflake)
- Data validation and quality assurance
- Public-safe analytical queries and summary metrics

Automation tools, credentials, and proprietary models used in the original
project are intentionally excluded.

## Scope and limitations

This repository presents a public, security-safe representation of the
CULTIVATE mapping and analysis pipeline.

**Not included**

- Automation tool source code
- Credentials (SAS tokens, keys, secrets)
- Partner or internal datasets
- Proprietary prompts, models, or classifiers

**Included**

- Dataset schemas and data contracts
- Public-safe SQL scripts (Snowflake)
- Validation and quality assurance checks
- Example configurations and synthetic samples

## Contributions and roles

This work was carried out within Work Package 2 (WP2) of the CULTIVATE project.

WP2 is led by Trinity College Dublin, under the academic leadership of
Professor Anna Davies (Project Coordinator and WP2 Leader).

Within WP2, the author contributed in a technical leading role, focusing on:

- the design and implementation of the mapping and analysis pipeline,
- data modelling and schema definition,
- cloud-based data ingestion and validation workflows,
- and the development of public-safe analytical queries.

The automation tool used for large-scale data collection and classification
was developed and maintained by Dublin City University (DCU) and the ADAPT Centre.

## Collaboration context

This work was developed within WP2 of the CULTIVATE project through close
collaboration between Trinity College Dublin (TCD) and Dublin City University (DCU).

- WP2 academic leadership: Trinity College Dublin
- Automation tool development: DCU / ADAPT Centre
- Mapping pipeline design, data modelling, validation, and analysis:
  TCD WP2 technical team

## Reference (automation tool)

The upstream automation tool (web retrieval + scraping + LLM-based classification) is described in:

Wu, H., Cho, H., Davies, A. R., & Jones, G. J. F. (2024).
_LLM-based Automated Web Retrieval and Text Classification of Food Sharing Initiatives_.
In _Proceedings of the 33rd ACM International Conference on Information and Knowledge Management (CIKM ’24)_.
DOI: 10.1145/3627673.3680090

> > > > > > > 699e276 (Initial structure and documentation for CULTIVATE mapping pipeline)
