# Deduplication Impact Analysis

## Overview

This analysis compares the pre-deduplication ShareCity200 dataset (3,140 FSIs) with the final deduplicated gold layer (3,052 FSIs) to quantify the impact of the deduplication process.

**Key Statistics:**
- **Before deduplication:** 3,140 FSIs
- **After deduplication:** 3,052 FSIs
- **Duplicates removed:** 88 FSIs
- **Deduplication rate:** 2.8%

---

## Setup Instructions

### Step 1: Upload ShareCity200 CSV to Azure (If not already done)

The pre-deduplication data needs to be uploaded to Azure Blob Storage first.

**Option A: Using Azure CLI**
```bash
# Load environment variables
source .env

# Upload file
az storage blob upload \
  --account-name $AZURE_STORAGE_ACCOUNT_NAME \
  --account-key $AZURE_STORAGE_KEY \
  --container-name $AZURE_CONTAINER_NAME \
  --name bronze/duplication/sharecity200-export-1768225380870.csv \
  --file data/bronze/duplication/sharecity200-export-1768225380870.csv
```

**Option B: Using Azure Storage Explorer**
1. Open Azure Storage Explorer
2. Connect to your storage account
3. Navigate to the `cultivatedata` container
4. Create folder: `bronze/duplication/`
5. Upload: `data/bronze/duplication/sharecity200-export-1768225380870.csv`

**Option C: Using Azure Portal**
1. Go to Azure Portal → Storage Account → Containers
2. Select `cultivatedata` container
3. Create folder structure: `bronze/duplication/`
4. Upload the CSV file

---

### Step 2: Create Snowflake Table and Load Data

Run the SQL script to create the bronze table and load data:

```bash
# Execute Snowflake SQL
snowsql -f snowflake/08_bronze_sharecity200.sql
```

Or run directly in Snowflake Worksheets:
```sql
-- See: snowflake/08_bronze_sharecity200.sql
```

**Validation:**
```sql
-- Check row count (should be 3,140)
SELECT COUNT(*) FROM bronze_sharecity200_raw;

-- Check top cities
SELECT city, country, COUNT(*) as count
FROM bronze_sharecity200_raw
GROUP BY city, country
ORDER BY count DESC
LIMIT 10;
```

Expected top city: **Barcelona** with highest FSI count.

---

### Step 3: Run dbt Comparison Model

Once the bronze table is loaded, run the dbt comparison model:

```bash
# Run the deduplication impact model
dbt run --select fsi_deduplication_impact

# Verify results
dbt show --select fsi_deduplication_impact
```

---

## Analysis Outputs

### Model: `fsi_deduplication_impact`

**Location:** `models/marts/fsi_deduplication_impact.sql`

**Columns:**
- `city` - City name
- `country` - Country name
- `fsi_count_before` - FSI count before deduplication
- `fsi_count_after` - FSI count after deduplication
- `duplicates_removed` - Number of duplicates removed
- `dedup_rate_pct` - Percentage of FSIs that were duplicates
- `status` - Deduplication status (No duplicates, Duplicates found, etc.)

**Summary Row:**
- First row shows total across all cities (`city = 'TOTAL'`)

---

## Query Results

### Overall Summary

```sql
SELECT
    fsi_count_before,
    fsi_count_after,
    duplicates_removed,
    dedup_rate_pct
FROM cultivate_db.public.fsi_deduplication_impact
WHERE city = 'TOTAL';
```

Expected output:
| fsi_count_before | fsi_count_after | duplicates_removed | dedup_rate_pct |
|------------------|-----------------|-------------------|----------------|
| 3,140 | 3,052 | 88 | 2.80 |

---

### Cities with Most Duplicates

```sql
SELECT
    city,
    country,
    fsi_count_before,
    fsi_count_after,
    duplicates_removed,
    dedup_rate_pct
FROM cultivate_db.public.fsi_deduplication_impact
WHERE city != 'TOTAL'
  AND duplicates_removed > 0
ORDER BY duplicates_removed DESC
LIMIT 10;
```

Expected top cities with duplicates:
- **Milan** - 20 duplicates removed
- **Utrecht** - 15 duplicates removed
- **Turin** - 8 duplicates removed
- **Bordeaux** - 6 duplicates removed

(Based on README context: Milan 183→163, Utrecht 213→198, Turin 128→120, Bordeaux 146→140)

---

### Cities with No Duplicates

```sql
SELECT
    city,
    country,
    fsi_count_before,
    fsi_count_after
FROM cultivate_db.public.fsi_deduplication_impact
WHERE city != 'TOTAL'
  AND duplicates_removed = 0
ORDER BY fsi_count_after DESC;
```

Example: **Dublin** (83 FSIs, no duplicates)

---

### Deduplication Rate by City

```sql
SELECT
    city,
    country,
    fsi_count_before,
    duplicates_removed,
    dedup_rate_pct
FROM cultivate_db.public.fsi_deduplication_impact
WHERE city != 'TOTAL'
ORDER BY dedup_rate_pct DESC
LIMIT 20;
```

This shows which cities had the highest percentage of duplicates.

---

## Export for Power BI

To use this data in Power BI dashboard:

1. **Add to Power BI data source:**
   - Connect to Snowflake
   - Select table: `cultivate_db.public.fsi_deduplication_impact`

2. **Create visuals:**
   - **KPI Card:** Total duplicates removed (88)
   - **Bar Chart:** Top 10 cities by duplicates removed
   - **Scatter Plot:** Dedup rate % vs FSI count
   - **Table:** Full city-level comparison

3. **DAX Measure:**
   ```dax
   Overall Dedup Rate =
   DIVIDE(
       SUM(fsi_deduplication_impact[duplicates_removed]),
       SUM(fsi_deduplication_impact[fsi_count_before]),
       0
   )
   ```

---

## Deduplication Methodology Reference

For details on how duplicates were detected, see:
- **Python Script:** [exploration/2026/01/scripts/detect_duplicates.py](../01/scripts/detect_duplicates.py)
- **Methodology:** [exploration/2026/01/scripts/README.md](../01/scripts/README.md)

**Strategies used:**
1. Exact match on normalized `country + city + name`
2. URL normalization and matching
3. Fuzzy string matching (92% similarity threshold)

---

## Next Steps

After running the comparison:

1. ✅ Validate total counts match expected (3,140 → 3,052)
2. ✅ Review cities with high deduplication rates (>5%)
3. ✅ Update final report with deduplication statistics
4. ✅ Add deduplication impact section to Power BI dashboard
5. ⏳ Document any unexpected findings (cities added/removed)

---

## Troubleshooting

**Issue:** `bronze_sharecity200_raw` table not found
- **Solution:** Run `snowflake/08_bronze_sharecity200.sql` first

**Issue:** Row count doesn't match 3,140
- **Solution:** Check CSV upload to Azure, verify COPY INTO completed successfully

**Issue:** dbt model fails with source not found
- **Solution:** Verify `models/sources.yml` includes `bronze_sharecity200_raw` definition

**Issue:** Gold data shows different count
- **Solution:** Verify you're using the correct gold_fsi_final table (post-deduplication)

---

## Files Created

**Snowflake:**
- [snowflake/08_bronze_sharecity200.sql](../../../snowflake/08_bronze_sharecity200.sql) - Table creation and data load

**dbt:**
- [models/sources.yml](../../../models/sources.yml) - Added bronze_sharecity200_raw source
- [models/marts/fsi_deduplication_impact.sql](../../../models/marts/fsi_deduplication_impact.sql) - Comparison model

**Documentation:**
- This file: `DEDUPLICATION_COMPARISON.md`

---

**Last Updated:** 2026-01-31
**Status:** Ready to run (pending CSV upload to Azure)
