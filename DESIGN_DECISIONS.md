# Design decisions: classification and persistence

## 1. Classification strategy

### Agent-based classification (current implementation)

Classification is performed using an agent-based approach, without persisting full-text corpora.  
The LLM agent retrieves and processes relevant page content on demand as part of each classification task.

#### Process

1. Retrieve candidate URL
2. Extract relevant textual segments on demand
3. Apply classification prompt and decision rules
4. Return structured labels and confidence signals

#### Rationale

This approach reduces storage overhead and avoids maintaining large archived text datasets.  
It also allows classification logic (prompts, decision rules, thresholds) to evolve over time without requiring costly reprocessing of historical corpora.

---

## 2. Retention and incremental operation

- Both positive and negative classifications are retained to avoid repeated re-classification.
- Scheduled incremental runs (e.g. monthly) may filter previously seen URLs.
- Domain-aware exceptions may apply (for example, platform-hosted pages where content evolves over time).

This design balances computational efficiency with sensitivity to change, particularly for initiatives hosted on dynamic platforms.

---

## 3. Quality checks and validation

Classification outputs are not treated as final truths. Multiple validation steps are applied to ensure robustness:

- Confidence thresholds are used to flag uncertain cases
- Duplicate and contradictory classifications are identified
- Manual spot checks are conducted on sampled outputs across cities and languages

Insights from these checks feed directly into analysis and interpretation, particularly in examining patterns of misclassification and under-recognition.

---

## 4. Iterative refinement loop

Classification is not a fixed endpoint.  
Instead, it operates within a feedback loop where analytical findings inform:

- prompt refinement
- decision rule adjustment
- upstream input preparation

This iterative setup supports improved sensitivity to diverse and context-specific food sharing practices over successive runs.

---

## 5. Classification logic

Classification is framed as a decision task guided by structured prompts.  
Each candidate URL is assessed using extracted textual content and associated metadata, producing both categorical labels and confidence signals.

---

## Database design principles

The database layer is designed to support classification, interpretation, and long-term maintenance rather than acting as a raw data dump.

### Core principles

**Separation of concerns**  
Raw discovery signals, classification outputs, and curated initiative records are stored as distinct entities with explicit relationships.

**Traceability and reproducibility**  
Each classification outcome is linked to its source URL, discovery context, and classification timestamp, allowing decisions to be audited and revisited.

**Incremental operation**  
Previously assessed sources are retained to avoid unnecessary re-processing, while allowing domain-aware exceptions where appropriate.

**Public-safe persistence**  
No full-text corpora, credentials, or sensitive partner data are persisted in the database layer exposed through this repository.

---

## Data entities and relationships (conceptual)

At a conceptual level, the database consists of four core entity groups:

### Candidate URLs

Discovered web sources prior to validation.

### Classification results

Model decisions, confidence signals, and rejection reasons.

### Scraped content (ephemeral or partial)

Used to support classification and validation, without persistent storage of full raw text at scale.

### Curated initiatives

Stable, human-readable records used for analysis, visualisation, and delivery through the Food Sharing Map.

These entities are linked through explicit foreign-key relationships, allowing the system to distinguish between discovery-level uncertainty and curated initiative-level knowledge.

(Full schema definitions and data contracts are documented separately in `schema/data_model.md`.)

---

## Role in the pipeline lifecycle

Within the broader pipeline, the database plays three distinct roles:

### 1. Boundary between automation and interpretation

The database marks the transition from automated discovery and classification to analytical interpretation.  
Downstream analyses operate on structured, validated records rather than raw web content.

### 2. Feedback support for methodological refinement

Stored classification outputs and validation signals inform subsequent refinements to prompts, decision rules, and input preparation.  
This enables the pipeline to evolve without discarding prior results.

### 3. Foundation for delivery and maintenance

Curated initiative records act as the authoritative source for:

- map visualisation and filtering
- longitudinal tracking of initiative status
- scheduled re-runs and updates

---

## Implementation notes (public-safe)

The database layer is implemented using a cloud data warehouse (Snowflake), with ingestion and transformation handled via version-controlled SQL scripts.

Only public-safe schemas, transformations, and validation logic are included in this repository.  
Operational credentials, internal datasets, and proprietary automation components are intentionally excluded.
