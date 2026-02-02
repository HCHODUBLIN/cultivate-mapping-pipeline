# Data Upload Recommendations for Snowflake

## Summary

Based on review of the `data/bronze/` folder, cleaned up unnecessary analysis outputs. Only source data files remain for Snowflake upload.

**Cleaned up (deleted):**
- ❌ FSI_all_cities_merged_withmanualdata.xlsx (manual data in gold layer comments)
- ❌ Analysis Excel files (Data_hubcities_overlap.xlsx, Overlap_11cities.xlsx, etc.)
- ❌ ShareCity200Tracker.xlsx (QA notes)
- ❌ 105analysis/ folder now empty

## Files to Upload

### 1. ✅ **PRIORITY: ShareCity200 Pre-Deduplication Dataset**

**File:** `data/bronze/duplication/sharecity200-export-1768225380870.csv`
- **Size:** 774 KB
- **Rows:** 3,140 FSIs (3,141 total rows including header)
- **Purpose:** Pre-deduplication reference dataset
- **Value:**
  - Compare pre vs post-deduplication (3,140 → 3,052 = 88-89 duplicates)
  - Historical baseline for all 105 cities automated mapping
  - Source dataset for deduplication analysis
  - Track changes over time

**Recommended Snowflake Table:** `bronze_sharecity200_raw`

**Columns:**
- Country, City, Name, URL
- Instagram URL, Twitter URL, Facebook URL
- Food Sharing Activities, How it is Shared
- Lon, Lat
- Comments, Date Checked, Date Modified

**Usage in dbt:**
```sql
-- staging/stg_sharecity200_raw.sql
-- Compare automated vs final deduplicated data
```

---

### 2. ⚠️ **CONDITIONAL: FSI Merged with Manual Data**

**File:** `data/bronze/105analysis/FSI_all_cities_merged_withmanualdata.xlsx`
- **Size:** 324 KB
- **Purpose:** Merged dataset combining automated + manual hub city mapping
- **Value:**
  - Track which FSIs came from automated vs manual mapping
  - Understand hub city (Barcelona, Utrecht, Milan) enrichment
  - Historical comparison

**Recommendation:** Upload **IF** this file contains the manual mapping metadata (e.g., source column indicating "automated" vs "manual"). Otherwise, this data is likely already in gold_fsi_final.

**Action Required:** Inspect file to verify it contains unique information not in gold layer.

---

### 3. 📊 **OPTIONAL: Analysis Outputs (Reference Only)**

**Files:**
- `Data_hubcities_overlap.xlsx` (84 KB) - Hub cities overlap analysis
- `Overlap_11cities.xlsx` (168 KB) - 11 cities overlap analysis
- `SHARECITY200 Cities_list.xlsx` (438 KB) - ShareCity200 cities list
- `merged_output.xlsx` (522 KB) - Merged output (purpose unclear)

**Recommendation:** **Do NOT upload** to Snowflake initially.

**Reason:**
- These appear to be analysis outputs or intermediate files
- Overlap analyses can be recreated via dbt queries on gold_fsi_final
- Cities list can be derived from the main datasets
- Unclear if merged_output.xlsx contains unique source data

**Action:** Store in `exploration/2026/03/` folder as supporting documentation, but not in the data warehouse.

---

### 4. 📝 **OPTIONAL: Verification Tracker**

**File:** `data/bronze/verification/ShareCity200Tracker.xlsx`
- **Size:** 45 KB
- **Purpose:** Manual review tracking/notes

**Recommendation:** **Do NOT upload** to Snowflake.

**Reason:**
- Likely contains manual QA notes, not source data
- Better suited for analysis folder documentation
- Can reference in analysis README if needed

---

## Recommended Next Steps

### Step 1: Upload ShareCity200 CSV to Azure

```bash
# Load environment variables
source .env

# Upload to Azure Blob Storage
az storage blob upload \
  --account-name $AZURE_STORAGE_ACCOUNT_NAME \
  --account-key $AZURE_STORAGE_KEY \
  --container-name $AZURE_CONTAINER_NAME \
  --name bronze/sharecity200/sharecity200-export-1768225380870.csv \
  --file data/bronze/duplication/sharecity200-export-1768225380870.csv
```

Or use the sync script:
```bash
./infra/infrastructure/azure/azure_sync.sh
```

### Step 2: Create Snowflake Stage and Load

```sql
-- Create external stage for ShareCity200
CREATE STAGE IF NOT EXISTS cultivate_db.public.sharecity200_stage
  URL = 'azure://cultivatedata.blob.core.windows.net/cultivatedata/bronze/sharecity200/'
  CREDENTIALS = (AZURE_SAS_TOKEN = '...');

-- Create table
CREATE TABLE IF NOT EXISTS cultivate_db.public.bronze_sharecity200_raw (
    country VARCHAR,
    city VARCHAR,
    name VARCHAR,
    url VARCHAR,
    instagram_url VARCHAR,
    twitter_url VARCHAR,
    facebook_url VARCHAR,
    food_sharing_activities VARCHAR,
    how_it_is_shared VARCHAR,
    lon FLOAT,
    lat FLOAT,
    comments VARCHAR,
    date_checked VARCHAR,
    date_modified TIMESTAMP
);

-- Load data
COPY INTO cultivate_db.public.bronze_sharecity200_raw
FROM @sharecity200_stage/sharecity200-export-1768225380870.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ENCODING = 'UTF8'
);
```

### Step 3: Add to dbt sources.yml

```yaml
  - name: bronze_sharecity200_raw
    description: |
      Pre-deduplication ShareCity200 export (3,140 FSIs)
      Used as baseline for automated mapping across 105 cities
      Compare with gold_fsi_final to track deduplication impact
    columns:
      - name: country
      - name: city
      - name: name
      - name: url
      - name: food_sharing_activities
        description: JSON array of activities
      - name: how_it_is_shared
        description: JSON array of sharing modes
      - name: lon
      - name: lat
      - name: date_checked
      - name: date_modified
```

### Step 4: Create Comparison Model (Optional)

```sql
-- models/analysis/fsi_deduplication_impact.sql
-- Compare pre vs post deduplication

with pre_dedup as (
    select
        city,
        country,
        count(*) as fsi_count_before
    from {{ source('cultivate', 'bronze_sharecity200_raw') }}
    group by city, country
),

post_dedup as (
    select
        city,
        country,
        count(*) as fsi_count_after
    from {{ source('cultivate', 'gold_fsi_final') }}
    group by city, country
)

select
    coalesce(pre.city, post.city) as city,
    coalesce(pre.country, post.country) as country,
    coalesce(pre.fsi_count_before, 0) as fsi_count_before,
    coalesce(post.fsi_count_after, 0) as fsi_count_after,
    coalesce(pre.fsi_count_before, 0) - coalesce(post.fsi_count_after, 0) as duplicates_removed,
    case
        when pre.fsi_count_before > 0
        then round((coalesce(pre.fsi_count_before, 0) - coalesce(post.fsi_count_after, 0)) * 100.0 / pre.fsi_count_before, 2)
        else 0
    end as dedup_rate_pct
from pre_dedup pre
full outer join post_dedup post
    on pre.city = post.city
    and pre.country = post.country
order by duplicates_removed desc
```

---

## Summary Table

| File/Folder | Upload? | Priority | Status |
|-------------|---------|----------|--------|
| `sharecity200-export-*.csv` | ✅ Yes | **HIGH** | Ready to upload |
| `false-positive/` reports | ❌ No | Low | Keep for documentation |
| `verification/` docs | ❌ No | Low | Keep for documentation |
| ~~105analysis/ files~~ | ❌ Deleted | - | Cleaned up |

---

## Next Action

Upload ShareCity200 CSV to Snowflake and create comparison model to track deduplication impact (3,140 → 3,052 FSIs).

---

**Last Updated:** 2026-01-31
**Author:** Analysis pipeline review
