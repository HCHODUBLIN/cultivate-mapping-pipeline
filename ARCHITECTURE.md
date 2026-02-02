# System architecture — Food Sharing Map pipeline

This document describes the end-to-end architecture of the Food Sharing Map automation pipeline, with a focus on data flow, persistence, and reuse.
The system is designed to support large-scale, iterative execution with incremental updates and minimal redundant processing.

## My role

As Data Solution Architect and Systems Design Lead for Sharing Solutions, I led the collaborative design and review of the end-to-end system architecture across the WP2 team.

## Pipeline overview (upstream)

```mermaid
flowchart LR
  A[Input <br/>preparation]
    --> B[Discovery & <br/>extraction]
    --> C[LLM-based <br/>classification]
    --> E[(FSI <br/>database)]

  E --> F[Delivery & <br/>maintenance]
  E --> G{Analysis & <br/>interpretation}
  G --> H[Method <br/>refinement]
  H --> A
```

## Input preparation

Defines what gets searched by producing consistent query inputs across cities and languages.

```mermaid
flowchart LR
  CL[(City list)]
    --> QD{Query <br/>design}

  FD[(FoodSharing Dictionary<br/>31 languages)]
    --> QD

  QD --> QT[Query templates<br/>& parameters]
```

**Inputs**: city list, multilingual keyword sets  
**Approach**: rule-based query templates informed by domain knowledge  
**Output**: structured query inputs for discovery

## Discovery & extraction

Generates a candidate URL set per city from search results, ready for classification.

**Architecture option 1: crawl-and-store pipeline**

```mermaid
flowchart LR
  QT[Query <br/>templates <br/>& parameters]
    --> GA[[Google <br/>API]]
    --> U[(Candidate <br/>URL list)]
    --> T[Web <br/>scraping <br/>Python + <br/>BeautifulSoup]
    --> N[Text <br/>normalisation]
    --> B{LLM-based <br/>text <br/>classification}
```

**Architecture option 2: agent-based on-the-fly classification**

```mermaid
flowchart LR
  QT[Query templates & parameters]
    --> GA[[Google API]]
    --> U[(Candidate URL list)]
    --> B{Agent-based <br/>LLM classification<br/>on-the-fly extraction}
```

- Current implementation adopts the agent-based on-the-fly architecture, reducing the need for persistent storage of large-scale full-text corpora.

## LLM-based classification

Turns candidate URLs into labelled records (valid/invalid + type), with manual review used to improve decision rules over time.

```mermaid
flowchart LR
  U[(Candidate <br/>URL list)]

  subgraph A[LLM agent - OpenAI API]
    R[On-the-fly <br/>text retrieval]
    D{Candidate <br/>assessment}
    C[Activity <br/>& sharing mode<br/>categorisation]
    P[Prompt <br/>refinement]

    R --> D --> C
    P -.-> D
  end

  U --> R

  GIS[Geolocation inference]
  G[[Google Places API]] --> GIS

  C --> M[/Manual <br/>verification/]
  GIS --> M
  M --> P

  M --> L[Labels <br/>+ confidence]
  L --> E[(FSI <br/>database)]
```

**Inputs**: Normalised text content, source URL, city context, and query metadata  
**Approach**: Prompt-based LLM classification informed by domain-specific criteria  
**Outputs**: Binary and categorical labels indicating relevance and initiative type. Manual verification feeds back into prompt and rule updates

## FSI database

Persists classification outcomes and curated initiatives, enabling incremental re-runs (skip already-seen URLs) and powering analysis and delivery.

```mermaid
flowchart LR
  U[(Candidate URLs)]
  C[Classification results]
  I[(Curated initiatives)]

  U --> C --> I
  I --> A[Analysis]
  I --> D[Delivery]
  C --> R[Refinement loop]
```

### Conceptual data model (summary)

The FSI database is organised around a small number of core entities with clear, intentional relationships.
This structure supports incremental operation, traceability, and separation between discovery and curation. See [schema/ERD.dbml](schema/ERD.dbml) for the full ERD.

| Column                  | Type              | Description                             |
| ----------------------- | ----------------- | --------------------------------------- |
| initiative_id           | STRING            | Stable internal identifier              |
| name                    | STRING            | Curated initiative name                 |
| country                 | STRING            | Country where the initiative operates   |
| city                    | STRING            | City where the initiative is located    |
| canonical_url           | STRING            | Canonical website or primary source URL |
| instagram_url           | STRING (nullable) | Instagram page (if available)           |
| twitter_url             | STRING (nullable) | Twitter / X page (if available)         |
| facebook_url            | STRING (nullable) | Facebook page (if available)            |
| food_sharing_activities | STRING            | Activity labels (multi-value)           |
| how_it_is_shared        | STRING            | Sharing modality / mode                 |
| lon                     | FLOAT (nullable)  | Longitude (WGS84)                       |
| lat                     | FLOAT (nullable)  | Latitude (WGS84)                        |
| comments                | STRING (nullable) | Manual notes and contextual remarks     |
| date_checked            | DATE (nullable)   | Latest manual verification date         |
| date_modified           | DATE (nullable)   | Last curation update date               |

## Delivery

Consumes curated initiative records from the FSI database to power external outputs and scheduled updates.

```mermaid
flowchart LR
  DB[(FSI database)]
  DB --> M[Map visualisation]
  DB --> A[API / data export]
  DB --> S[Scheduled refresh jobs]
```

- Operates on curated, stable records
- No dependency on raw web content

## Analysis

Runs analytical and quality-check queries on curated initiatives and classification outcomes.

```mermaid
flowchart LR
  DB[(FSI database)]
    --> Q[Analytical SQL queries]
    --> QC[Quality checks]
    --> SUM[City-level summaries]
```

- Aggregate metrics and coverage assessment
- Supports monitoring and validation across runs

## Method refinement

Uses stored classification outcomes and manual review signals to adjust classification prompts and rules in subsequent runs.

```mermaid
flowchart LR
  DB[(FSI database)]
    --> R[Review signals]
    --> U[Prompt / rule updates]
    --> Run[Next pipeline run]
```

- No reprocessing unless explicitly triggered
- Focused on incremental improvement, not re-labelling from scratch
