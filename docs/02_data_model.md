## Automation tool overview (upstream)

```mermaid
flowchart LR
  A[City list + multilingual food sharing vocabulary] --> B[Query formation & expansion]
  B --> C[Web search (API) → candidate URLs]
  C --> D[Blacklist filtering]
  D --> E[Web scraping: target page + about page]
  E --> F[Text normalisation + metadata extraction]
  F --> G[LLM-based FSI classification]
  G --> H[(FSI database: positive + negative records)]
  H --> I[Scheduled re-runs: avoid re-classifying known URLs]
  H --> J[Presentation layer (platform)]
```

## Automation output (public-safe data contract)

The automation tool produces a set of candidate URLs for each city and enriches
them through scraping and LLM-based classification. The downstream pipeline
(Azure → Snowflake) treats these outputs as an input contract.

### Entity: Candidate URL

- `candidate_id` (string; generated)
- `city` (string)
- `country` (string; optional)
- `source_url` (string)
- `discovered_at` (timestamp)
- `query_phrase` (string; optional)
- `query_method` (enum: `dictionary` | `okapi` | `yake` | `llm`; optional)
- `is_blacklisted` (boolean)
- `blacklist_reason` (string; optional)

### Entity: Scraped content

- `candidate_id` (string; FK → Candidate URL)
- `page_url` (string)
- `about_url` (string; optional)
- `scraped_at` (timestamp)
- `page_text` (string)
- `about_text` (string; optional)
- `language` (string; optional)
- `word_count` (integer; optional)

### Entity: Classification result

- `candidate_id` (string; FK → Candidate URL)
- `classified_at` (timestamp)
- `model_family` (string; public-safe label, e.g. ChatGPT-4 / LLaMA2)
- `label` (enum: `valid_fsi` | `invalid_fsi`)
- `confidence` (number; optional)
- `reject_reason` (string; optional)
- `category` (string; optional; coarse category label)

### Entity: Initiative (curated record)

- `initiative_id` (string; stable ID generated downstream)
- `city` (string)
- `name` (string; extracted and/or manually edited)
- `canonical_url` (string)
- `description` (string; optional)
- `categories` (string or array; optional)
- `last_seen_at` (timestamp)
- `status` (enum: `active` | `unknown` | `inactive`; optional)

### Notes

- Both positive and negative classifications are retained to avoid repeated re-classification.
- Scheduled incremental runs (e.g. monthly) may filter previously seen URLs. Domain-aware exceptions may apply (e.g. platform-hosted pages).
