# CULTIVATE dbt Models

This directory contains the dbt transformation layer for the CULTIVATE FSI mapping pipeline, implementing a **Medallion Architecture**.

---

## 📊 Entity Relationship Diagram

The complete ERD documentation is in the `schema/` directory alongside the conceptual data model.

### Interactive ERD (Recommended)
For the best visualization experience:
1. Open [schema/ERD.dbml](../schema/ERD.dbml)
2. Copy all contents
3. Paste into [https://dbdiagram.io](https://dbdiagram.io)
4. Explore the interactive ERD with full relationships and documentation

### Markdown ERD
View [schema/ERD.md](../schema/ERD.md) for a Mermaid diagram that renders directly in GitHub/VSCode.

### Conceptual Model
See [schema/data_model.md](../schema/data_model.md) for the complete data model documentation, including:
- Automation output data contract
- Curated export schema
- Conceptual internal model
- Snowflake implementation (Bronze/Silver/Gold)

---

## 🏗️ Architecture

### Medallion Architecture
```
Bronze (Raw) → Silver (Staging) → Gold (Business Marts)
```

### Layer Breakdown

#### Bronze Layer - Raw Data (`sources.yml`)
- **raw_automation**: URLs from automation (5 rounds: v1.0.0 → v2.0.0)
- **raw_automation_reviewed**: Manual review decisions
- **raw_ground_truth**: Ground truth URLs for validation
- **raw_city_language**: City-to-language mapping
- **raw_manual_verification**: Manual verification (105 cities, 5 rounds)
- **bronze_sharecity200_raw**: Pre-deduplication data (3,140 FSIs)
- **gold_fsi_final**: Post-deduplication gold data (3,052 FSIs)

#### Silver Layer - Staging (`staging/`)
Clean, transformed, and normalized data:
- **stg_automation**: Cleaned automation URLs
- **stg_automation_enhanced**: URL normalization (MDM)
- **stg_automation_review**: BOOLEAN conversion for review decisions
- **stg_ground_truth**: Cleaned ground truth
- **stg_ground_truth_enhanced**: Ground truth with URL normalization
- **stg_manual_verification**: Cleaned manual verification data

#### Gold Layer - Business Marts (`marts/`)

**FSI Landscape Analysis:**
- **fsi_city_summary**: City-level FSI statistics with population metrics
- **fsi_cluster_analysis**: Regional aggregation (Southern, Western, Northern, Eastern Europe)
- **fsi_activity_summary**: Activity breakdown (Distribution, Growing, Cooking & Eating)
- **fsi_deduplication_impact**: Pre vs post deduplication comparison (3,140 → 3,052)

**Pipeline Evaluation:**
- **accuracy_comparison**: Automation accuracy improvement (32% → 74%)
- **manual_verification_summary**: Aggregated verification by city and round
- **fp_pattern_analysis**: False positive categorization
- **mart_pipeline_eval**: Precision, recall, F1 metrics
- **mart_mapping_comparison**: Automation vs ground truth comparison

---

## ✅ Data Quality Testing

Comprehensive dbt tests ensure data integrity across all layers.

### Test Coverage

#### Source Tests (`sources.yml`)
- **Uniqueness**: Primary keys (automation_id, ground_truth_id, etc.)
- **Not Null**: Critical fields (city, source_url, etc.)
- **Total Count**: Bronze (3,140), Gold (3,052)

#### Staging Tests (`staging/schema.yml`)
- **Uniqueness**: All primary keys
- **Not Null**: Required fields
- **Relationships**: Foreign key integrity (automation_id → stg_automation)
- **Accepted Values**: BOOLEAN, round versions, FP categories

#### Marts Tests (`marts/schema.yml`)
- **Uniqueness**: City-level aggregations
- **Not Null**: All metrics
- **Accepted Range**: Percentages (0-100), metrics (≥0)
- **Accepted Values**: Regional clusters, FP categories, round versions
- **Expression Tests**: Total FSI count = 3,052

### Running Tests

```bash
# Run all tests
dbt test

# Run tests for specific layer
dbt test --select staging
dbt test --select marts

# Run tests for specific model
dbt test --select fsi_city_summary
dbt test --select fsi_deduplication_impact

# Run tests for sources only
dbt test --select source:*

# Run specific test types
dbt test --select test_type:unique
dbt test --select test_type:not_null
dbt test --select test_type:relationships
```

### Test Categories

1. **Schema Tests** (built-in):
   - `unique`: Ensures primary key uniqueness
   - `not_null`: Ensures critical fields are populated
   - `relationships`: Validates foreign key integrity
   - `accepted_values`: Validates categorical fields

2. **Data Tests** (dbt_utils):
   - `accepted_range`: Validates numeric ranges (e.g., 0-100 for percentages)
   - `expression_is_true`: Custom SQL validation (e.g., total count = 3,052)

---

## 🔑 Key Features

### 1. URL Normalization as MDM
Master Data Management through URL normalization:
- Lowercase conversion
- Remove www/https prefixes
- Domain extraction for deduplication
- Implemented in `stg_automation_enhanced` and `stg_ground_truth_enhanced`

### 2. Multi-Strategy Deduplication
Three-pronged approach:
- **Exact matching**: Normalized country+city+name
- **URL-based**: Normalized URL comparison
- **Fuzzy matching**: 92% similarity threshold (Levenshtein distance)

**Results**: 3,140 FSIs → 3,052 FSIs (88 duplicates removed, 2.8% dedup rate)

### 3. Confidence Scoring
Uncertainty management:
- **Manual verification**: FP categorization (VALID, FP_MEDIA, FP_COMMERCIAL, etc.)
- **Accuracy tracking**: 32% (v1.0.0) → 74% (v2.0.0 agent-based, +42% improvement)
- **Quality metrics**: Precision, recall, F1 score per city

### 4. Regional Cluster Analysis
Geographic grouping for comparative analysis:
- Southern Europe
- Western Europe
- Northern Europe
- Eastern Europe

Enables regional FSI density comparison and pattern identification.

---

## 📈 Metrics & KPIs

### FSI Density
- **fsis_per_100k**: FSIs per 100,000 population
- Enables fair comparison across cities of different sizes

### Accuracy Improvement
- **Baseline (v1.0.0)**: 32.02% accuracy (73/228 validated FSIs)
- **Final (v2.0.0)**: 74% accuracy (agent-based approach)
- **Improvement**: +42% from baseline

### Deduplication Impact
- **Pre-deduplication**: 3,140 FSIs (bronze_sharecity200_raw)
- **Post-deduplication**: 3,052 FSIs (gold_fsi_final)
- **Duplicates Removed**: 88 FSIs (2.8% dedup rate)

### False Positive Reduction
- **FP_MEDIA**: News articles, magazines
- **FP_COMMERCIAL**: Restaurants, grocery stores
- **FP_CROWDFUNDING**: Kickstarter, GoFundMe
- **FP_MUSEUM**: Museums, exhibitions
- **FP_OTHER**: Miscellaneous false positives

---

## 🛠️ Development

### Prerequisites
```bash
# Install dbt with Snowflake adapter
pip install dbt-snowflake

# Install dbt_utils for custom tests
dbt deps
```

### Running Models

```bash
# Run all models
dbt run

# Run specific layer
dbt run --select staging
dbt run --select marts

# Run specific model and dependents
dbt run --select fsi_city_summary+

# Run specific model and dependencies
dbt run --select +fsi_city_summary

# Full refresh (recreate tables)
dbt run --full-refresh
```

### Documentation

```bash
# Generate documentation (includes ERD via dbt lineage graph)
dbt docs generate

# Serve documentation locally at http://localhost:8080
dbt docs serve
```

---

## 📁 File Structure

```
models/
├── sources.yml              # Source table definitions with tests
├── README.md                # This file
├── staging/
│   ├── schema.yml           # Staging model tests
│   ├── stg_automation.sql
│   ├── stg_automation_enhanced.sql
│   ├── stg_automation_review.sql
│   ├── stg_ground_truth.sql
│   ├── stg_ground_truth_enhanced.sql
│   ├── stg_city_language.sql
│   └── stg_manual_verification.sql
└── marts/
    ├── schema.yml           # Mart model tests
    ├── fsi_city_summary.sql
    ├── fsi_cluster_analysis.sql
    ├── fsi_activity_summary.sql
    ├── fsi_deduplication_impact.sql
    ├── accuracy_comparison.sql
    ├── manual_verification_summary.sql
    ├── fp_pattern_analysis.sql
    ├── mart_pipeline_eval.sql
    ├── mart_mapping_comparison.sql
    └── mart_mapping_comparison_total.sql
```

---

## 🎯 Best Practices

1. **Always run tests**: `dbt test` before `git commit`
2. **Document changes**: Update [schema/ERD.dbml](../schema/ERD.dbml) when schema changes
3. **Follow naming conventions**:
   - Sources: `raw_*`
   - Staging: `stg_*`
   - Marts: `mart_*` or domain-specific (e.g., `fsi_*`)
4. **Use consistent date formats**: TIMESTAMP_NTZ in Snowflake
5. **Add tests for new models**: Update schema.yml files
6. **Version control**: Track all SQL and YAML files in git

---

## 📊 Visualization

### Power BI Dashboard
See [exploration/2026/03_landscape_analysis/POWERBI_SETUP.md](../exploration/2026/03_landscape_analysis/POWERBI_SETUP.md) for Power BI dashboard setup.

**Key Visuals:**
- City-level FSI map with density heatmap
- Regional cluster comparison (Southern, Western, Northern, Eastern Europe)
- Activity breakdown (Distribution, Growing, Cooking & Eating)
- Deduplication impact (3,140 → 3,052)
- Accuracy improvement trend (32% → 74%)

### dbt Lineage Graph
```bash
dbt docs generate
dbt docs serve
```
Navigate to http://localhost:8080 and explore the interactive lineage graph.

---

*Documentation for CULTIVATE FSI Mapping Pipeline - 105 European Cities, 3,052 Food Sharing Initiatives*
