# FSI Landscape Analysis - 105 Cities (2026/03)

## Overview

**Status:** 🟡 In Progress
**Purpose:** Analyze final deduplicated FSI dataset across 105 European cities
**Data Source:** Gold layer (`gold_fsi_final`) - Post-deduplication

## Key Updates from Previous Version

**Previous (Sep 2025):** 3,141 FSIs before deduplication
**Current (Jan 2026):** 3,052 FSIs after deduplication
**Duplicates Removed:** 89 FSIs

### Top City Changes

| City | Before | After | Removed |
|------|--------|-------|---------|
| Barcelona | 263 | 261 | -2 |
| Utrecht | 213 | 198 | -15 |
| Milan | 183 | 163 | -20 |
| Bordeaux | 146 | 140 | -6 |
| Turin | 128 | 120 | -8 |
| Lyon | 112 | 111 | -1 |
| Dublin | 83 | 83 | 0 |

## Analysis Components

### dbt Mart Models

Located in `/models/marts/`:

1. **`fsi_city_summary.sql`**
   - City-level FSI counts
   - FSIs per 100,000 population
   - Regional cluster assignment
   - Rankings (by count, per capita, within cluster)

2. **`fsi_cluster_analysis.sql`**
   - Regional cluster aggregation (Southern, Western, Northern, Eastern Europe)
   - Cluster-level statistics
   - Population-weighted FSI density
   - Percentage of total FSIs by cluster

3. **`fsi_activity_summary.sql`**
   - Food sharing activities breakdown (Distribution, Growing, Cooking & Eating)
   - Sharing modes analysis (Gifting, Selling, Bartering)
   - Multiple activity distribution
   - Percentage calculations

### Regional Clusters

**Southern Europe:**
- Barcelona, Milan, Turin, Bari, Seville, Ljubljana
- Highest FSI density per capita

**Western Europe:**
- Utrecht, Bordeaux, Lyon, Dublin, Nantes, Brighton and Hove, Dresden
- Second-highest FSI activity

**Northern Europe:**
- Copenhagen, Oslo, Stockholm, Helsinki
- Lower density, smaller populations

**Eastern Europe:**
- Brno, Warsaw, Prague, Budapest, Kyiv
- Moderate density, medium population range

**Other / Neighbourhood:**
- Auckland, Jerusalem, Rabat, Tbilisi, Tunis, Yerevan, Ankara
- Outside European context, insufficient comparable data

## Running the Analysis

### Using dbt

```bash
# Run all FSI landscape mart models
dbt run --select fsi_city_summary fsi_cluster_analysis fsi_activity_summary

# Or run individually
dbt run --select fsi_city_summary
dbt run --select fsi_cluster_analysis
dbt run --select fsi_activity_summary

# Generate documentation
dbt docs generate
dbt docs serve
```

### Query Results

After running dbt models, query the mart tables in Snowflake:

```sql
-- Top 20 cities by FSI count
SELECT city, country, fsi_count, fsis_per_100k, regional_cluster
FROM cultivate_db.public.fsi_city_summary
ORDER BY fsi_count DESC
LIMIT 20;

-- Cluster summary
SELECT regional_cluster, total_fsis, num_cities, fsis_per_100k
FROM cultivate_db.public.fsi_cluster_analysis
ORDER BY fsis_per_100k DESC;

-- Activity breakdown
SELECT metric_name, fsi_count, pct_of_total
FROM cultivate_db.public.fsi_activity_summary
WHERE metric_type = 'Activity'
ORDER BY fsi_count DESC;
```

## Data Source

**Snowflake Table:** `cultivate_db.public.gold_fsi_final`

This table contains the final deduplicated FSI dataset:
- 3,052 FSIs across 105 cities
- Post-duplication check (see `analysis/2026/01/` for deduplication methodology)
- Includes: FSI metadata, activities, sharing modes, geolocation

## Original Report

The original draft report (pre-deduplication) is in:
- `analysis/2026/03/SummaryReport_0912_final.docx`

This report will be updated with the new statistics from the dbt mart models.

## Key Findings (Updated)

### Overall Statistics
- **Total FSIs:** 3,052 (down from 3,141)
- **Cities Mapped:** 105 European urban and peri-urban areas
- **Duplication Rate:** 2.8% (89 duplicates removed)

### Food Sharing Activities
- **Distribution:** Most common activity
- **Growing:** Second most common
- **Cooking & Eating:** Often combined with other activities
- **Multiple Activities:** ~67% of cooking/eating FSIs also do distribution or growing

### Regional Patterns
- **Southern/Western Europe:** Highest FSI density (12.29 FSIs per 100k)
- **Northern Europe:** Lower density (3.88 FSIs per 100k)
- **Eastern Europe:** Moderate density (4.70 FSIs per 100k, excluding Kyiv)

### Population Correlation
- Within-cluster correlation stronger than overall
- Cultural-regional factors more decisive than population size alone

## Dependencies

**dbt:**
```bash
pip install dbt-snowflake
```

**Snowflake Access:**
- Database: `cultivate_db`
- Schema: `public`
- Required tables: `gold_fsi_final`

## Next Steps

1. ✅ Create dbt mart models
2. ⏳ Run dbt models in Snowflake
3. ⏳ Export updated statistics
4. ⏳ Update Word document with new numbers
5. ⏳ Generate visualizations (city maps, cluster comparisons)
6. ⏳ Finalize report for publication (Feb 2026)

## Related Work

- **Deduplication:** See [../01/scripts/](../01/scripts/detect_duplicates.py)
- **Manual Verification:** See [../../legacy_2025/01/](../../legacy_2025/01/)
- **Automation Improvement:** See [../../legacy_2025/02/](../../legacy_2025/02/)
