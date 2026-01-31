# Analysis Pipeline Guide

This guide explains how to use the two complementary analysis approaches for evaluating automation performance.

## Overview

The CULTIVATE mapping pipeline includes two analysis methods:

1. **Domain-level matching** - Fast statistical overview
2. **Similarity-based matching** - Detailed matching with manual review support

Both approaches use the same dbt staging models to ensure consistent URL normalisation.

---

## Method 1: Domain-Level Matching

**Purpose**: Quick performance metrics aggregated by language, version, and city.

**Best for**:
- High-level performance dashboards
- Comparing automation versions
- Language-specific analysis
- Quarterly/monthly reporting

### Files

- **Snowflake**: `snowflake/08_analysis.sql`
- **Python**: `scripts/analysis_report.py`
- **dbt models**: `models/staging/stg_*.sql`

### Snowflake Usage

```sql
-- Run analysis views
SOURCE snowflake/08_analysis.sql;

-- View metrics by language
SELECT * FROM v_metrics_by_language;

-- View detailed breakdown
SELECT * FROM v_metrics_detailed
WHERE city = 'cork';

-- Find missing ground truth URLs
SELECT * FROM v_missing_ground_truth
WHERE search_language = 'English';
```

### Python Usage

```bash
# Install dependencies
pip3 install -r requirements.txt

# Run analysis
python3 scripts/analysis_report.py

# Output files in reports/:
# - analysis_report_TIMESTAMP.txt
# - metrics_by_language_TIMESTAMP.png
# - metrics_by_version_TIMESTAMP.png
```

### Key Metrics

| Metric | Description | Formula |
|--------|-------------|---------|
| **Recall** | % of ground truth found by automation | `found / total_ground_truth` |
| **Precision** | % of automation results that are valid | `correct / total_automation` |
| **F1 Score** | Harmonic mean of recall and precision | `2 * (R * P) / (R + P)` |

### Limitations

- Uses **domain-level matching** (e.g., `facebook.com`)
- Cannot distinguish different pages on same domain
- May overestimate recall for platforms like Facebook/Instagram
- Best for aggregated statistics, not individual URL validation

---

## Method 2: Similarity-Based Matching

**Purpose**: Detailed URL matching with confidence scores for manual review.

**Best for**:
- Identifying specific matches for validation
- Handling platform URLs (Facebook, Instagram)
- Creating manual review queues
- Understanding why specific URLs didn't match

### Files

- **Snowflake**: `snowflake/09_similarity_matching.sql`
- **Python**: `scripts/similarity_analysis.py`
- **dbt models**: `models/staging/stg_*_enhanced.sql`

### Snowflake Usage

```sql
-- Run similarity matching views
SOURCE snowflake/09_similarity_matching.sql;

-- View all matches for a ground truth URL
SELECT * FROM v_url_matches_all_levels
WHERE ground_truth_id = 'ground_truth_001';

-- View best match per ground truth URL
SELECT * FROM v_url_best_matches
WHERE city = 'galway';

-- View manual review queue (prioritised)
SELECT * FROM v_manual_review_queue
WHERE confidence_score >= 50
LIMIT 50;

-- View summary by confidence level
SELECT * FROM v_match_summary_by_level;

-- View unmatched URLs
SELECT * FROM v_unmatched_ground_truth;
```

### Python Usage

```bash
# Run similarity analysis
python3 scripts/similarity_analysis.py

# Output files in reports/:
# - similarity_matches_full_TIMESTAMP.csv      (all matches)
# - manual_review_queue_TIMESTAMP.csv          (needs review)
# - similarity_summary_TIMESTAMP.txt           (statistics)
```

### Confidence Levels

| Level | Confidence | Description | Action |
|-------|------------|-------------|--------|
| **exact_url** | 100% | Exact URL match | Auto-accept |
| **domain_path1** | 75% | Same domain + first path segment (e.g., `facebook.com/groups/*`) | Manual review |
| **domain_only** | 40% | Same domain (unique sites) | Manual review |
| **domain_platform** | 20% | Same domain (Facebook/Instagram/etc) | Manual review required |

### Example Matches

```sql
-- Exact match (confidence: 100%)
Ground truth: urbansoilproject.com
Automation:   urbansoilproject.com/?fbclid=...
Match level:  exact_url
Action:       AUTO_ACCEPT

-- Domain + path match (confidence: 75%)
Ground truth: facebook.com/groups/urban-garden-cork
Automation:   facebook.com/groups/urban-garden-cork/posts/123
Match level:  domain_path1
Action:       MANUAL_REVIEW (check if same group)

-- Domain only - platform (confidence: 20%)
Ground truth: facebook.com/groups/garden-cork
Automation:   facebook.com/events/community-fest
Match level:  domain_platform
Action:       MANUAL_REVIEW (different sections - likely no match)
```

### Manual Review Workflow

1. **Export review queue**:
   ```sql
   SELECT * FROM v_manual_review_queue
   WHERE confidence_score >= 50
   ORDER BY confidence_score DESC;
   ```

2. **Review CSV** (`manual_review_queue_TIMESTAMP.csv`):
   - Sort by `confidence_score` (highest first)
   - Check `url_similarity_pct` and `combined_similarity_pct`
   - Compare `gt_url` and `auto_url` side-by-side

3. **Decision criteria**:
   - **Accept** if URLs point to same resource/organisation
   - **Reject** if different pages on same platform
   - **Uncertain** → Mark for secondary review

4. **Update automation results** based on validated matches

---

## Comparison: When to Use Which Method

| Scenario | Domain-Level | Similarity-Based |
|----------|--------------|------------------|
| Monthly performance report | ✅ | ❌ |
| Compare v1 vs v2 automation | ✅ | ❌ |
| Identify language gaps | ✅ | ❌ |
| Validate Facebook/Instagram matches | ❌ | ✅ |
| Create manual review queue | ❌ | ✅ |
| Understand individual URL misses | ❌ | ✅ |
| Quick dashboard metrics | ✅ | ❌ |
| Detailed match investigation | ❌ | ✅ |

---

## Technical Details

### URL Normalisation (dbt staging models)

Both methods use consistent URL normalisation:

1. Remove `http://` or `https://`
2. Remove `www.`
3. Remove query parameters (`?...`) and fragments (`#...`)
4. Remove trailing slashes
5. Remove trailing quotes
6. Remove whitespace
7. Convert to lowercase

**Enhanced models** additionally extract:
- `domain` - domain name only
- `path_segment_1` - first path segment (e.g., `groups` in `facebook.com/groups/abc`)
- `domain_path1` - combined (e.g., `facebook.com/groups`)
- `url_depth` - number of path segments

### dbt Model Structure

```
models/
├── staging/
│   ├── stg_ground_truth.sql           # Basic normalisation
│   ├── stg_automation.sql              # Basic normalisation
│   ├── stg_ground_truth_enhanced.sql  # + path segments
│   ├── stg_automation_enhanced.sql     # + path segments
│   ├── stg_automation_review.sql       # Boolean conversion
│   └── stg_city_language.sql          # City normalisation
└── marts/
    └── mart_mapping_comparison.sql     # Combined metrics
```

### Python Similarity Algorithms

**String Similarity** (SequenceMatcher):
- Compares character-level similarity
- Returns ratio 0.0-1.0
- Good for detecting typos and minor variations

**Token Similarity** (Jaccard):
- Compares URL path segments as sets
- Returns ratio 0.0-1.0
- Good for detecting shared path structures

**Combined Score**:
```
combined = (string_similarity * 0.7) + (token_similarity * 0.3)
```

---

## Output Files Reference

### Domain-Level Analysis

| File | Content | Use |
|------|---------|-----|
| `analysis_report_TIMESTAMP.txt` | Full text report with all metrics | Read-only review |
| `metrics_by_language_TIMESTAMP.png` | Bar charts by language | Presentations |
| `metrics_by_version_TIMESTAMP.png` | Bar charts by version | Version comparison |

### Similarity-Based Analysis

| File | Content | Use |
|------|---------|-----|
| `similarity_matches_full_TIMESTAMP.csv` | All potential matches with scores | Data analysis |
| `manual_review_queue_TIMESTAMP.csv` | Matches requiring review | Manual validation |
| `similarity_summary_TIMESTAMP.txt` | Statistics and high-confidence matches | Quick overview |

---

## Common Questions

### Q: Why are recall numbers different between methods?

**A**: Domain-level matching counts `facebook.com` matches broadly, while similarity-based
matching distinguishes `facebook.com/groups/*` from `facebook.com/events/*`.

### Q: Which method is more accurate?

**A**: Similarity-based is more precise for platforms like Facebook, but requires manual
review. Domain-level is better for aggregated statistics.

### Q: Can I use both methods together?

**A**: Yes! Use domain-level for reporting and similarity-based for validation.

### Q: How do I handle low recall?

**A**: Check `v_unmatched_ground_truth` to see which URLs weren't found. Common reasons:
- Different domain entirely
- Automation searched wrong keywords
- Site no longer exists
- Site blocked crawling

### Q: What confidence score threshold should I use?

**A**:
- ≥75%: Usually valid, quick review recommended
- 50-74%: Needs careful review
- <50%: Likely false positive, detailed review required

---

## Contact

For questions about the analysis pipeline:
- See main README for project contacts
- Check academic paper (Wu et al., 2024) for methodology details
