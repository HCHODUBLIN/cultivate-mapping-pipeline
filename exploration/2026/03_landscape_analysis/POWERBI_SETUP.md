# Power BI Dashboard Setup Guide - FSI Landscape Analysis

## Overview

This guide walks through creating a Power BI dashboard for the 105 Cities FSI Landscape Analysis using Snowflake as the data source.

**Data Source:** Snowflake dbt mart models (post-deduplication)
**Final FSI Count:** 3,052 FSIs across 105 cities
**Dashboard Purpose:** Visualize FSI distribution, activities, and regional patterns

---

## 1. Data Connection

### Connect Power BI to Snowflake

1. Open **Power BI Desktop**

2. **Get Data** → **More** → Search "Snowflake"

3. Enter Snowflake credentials:
   ```
   Server: your_account.snowflakecomputing.com
   Warehouse: compute_wh
   ```

4. **Advanced options:**
   ```sql
   -- Optional: Use custom SQL query to optimize load
   SELECT * FROM cultivate_db.public.fsi_city_summary
   ```

5. Authentication:
   - Username: `your_snowflake_user`
   - Password: `your_snowflake_password`

### Import Required Tables

Select these dbt mart tables:

✅ **`fsi_city_summary`** - City-level statistics
- Columns: city, country, fsi_count, population, fsis_per_100k, regional_cluster, rankings

✅ **`fsi_cluster_analysis`** - Regional cluster aggregates
- Columns: regional_cluster, num_cities, total_fsis, fsis_per_100k, avg_fsis_per_city

✅ **`fsi_activity_summary`** - Activities and sharing modes
- Columns: metric_type, metric_name, fsi_count, pct_of_total

**Optional:** Import `gold_fsi_final` for detailed FSI-level analysis

---

## 2. Data Model Setup

### Relationships

No relationships needed if using individual mart tables (already aggregated).

If using `gold_fsi_final`:
- Create relationship: `gold_fsi_final[city]` → `fsi_city_summary[city]`

### Calculated Columns (if needed)

```dax
// In fsi_city_summary table
City Label =
fsi_city_summary[city] & " (" & fsi_city_summary[fsi_count] & ")"

// Hub City Flag
Is Hub City =
IF(
    fsi_city_summary[city] IN {"Barcelona", "Utrecht", "Milan"},
    "Hub City",
    "Other City"
)
```

---

## 3. DAX Measures

Create these measures in a dedicated **Measures** table:

### Key Metrics

```dax
Total FSIs = SUM(fsi_city_summary[fsi_count])

Total Cities = DISTINCTCOUNT(fsi_city_summary[city])

Average FSIs per City =
DIVIDE([Total FSIs], [Total Cities], 0)

Average FSIs per 100k =
AVERAGE(fsi_city_summary[fsis_per_100k])
```

### Cluster Metrics

```dax
FSIs in Southern Europe =
CALCULATE(
    [Total FSIs],
    fsi_city_summary[regional_cluster] = "Southern Europe"
)

FSIs in Western Europe =
CALCULATE(
    [Total FSIs],
    fsi_city_summary[regional_cluster] = "Western Europe"
)

Cluster with Most FSIs =
CALCULATE(
    MAX(fsi_cluster_analysis[regional_cluster]),
    TOPN(1, fsi_cluster_analysis, fsi_cluster_analysis[total_fsis], DESC)
)
```

### Comparisons

```dax
// Difference from previous version (before deduplication)
Previous Total FSIs = 3141  // Hardcoded from Sep 2025 report

FSIs Removed = [Previous Total FSIs] - [Total FSIs]

Deduplication Rate =
DIVIDE([FSIs Removed], [Previous Total FSIs], 0)
```

---

## 4. Dashboard Pages

### Page 1: Overview

**Layout:** KPI cards + summary visuals

**Visuals:**

1. **KPI Cards (Top row):**
   - Total FSIs: `[Total FSIs]`
   - Total Cities: `[Total Cities]`
   - Avg FSIs/City: `[Average FSIs per City]`
   - Duplicates Removed: `[FSIs Removed]`

2. **Map (Main visual):**
   - Type: **Filled Map** or **Azure Maps**
   - Location: `fsi_city_summary[city]`
   - Size: `fsi_city_summary[fsi_count]`
   - Color: `fsi_city_summary[regional_cluster]`
   - Tooltip: City, Country, FSI count, FSIs per 100k

3. **Bar Chart (Right side):**
   - Title: "Top 20 Cities by FSI Count"
   - Axis: `fsi_city_summary[city]`
   - Values: `fsi_city_summary[fsi_count]`
   - Sort: Descending by FSI count
   - Filter: Top 20

4. **Donut Chart (Bottom left):**
   - Title: "FSIs by Regional Cluster"
   - Legend: `fsi_cluster_analysis[regional_cluster]`
   - Values: `fsi_cluster_analysis[total_fsis]`
   - Data labels: Show percentage

---

### Page 2: City Analysis

**Layout:** Detailed city-level breakdown

**Visuals:**

1. **Table (Main):**
   - Columns:
     - City
     - Country
     - FSI Count
     - Population
     - FSIs per 100k
     - Regional Cluster
     - Rank by Count
   - Sort: By FSI count descending
   - Conditional formatting: Color scale on FSIs per 100k

2. **Scatter Chart:**
   - Title: "Population vs FSI Count"
   - X-axis: `fsi_city_summary[population]`
   - Y-axis: `fsi_city_summary[fsi_count]`
   - Legend: `fsi_city_summary[regional_cluster]`
   - Size: `fsi_city_summary[fsis_per_100k]`
   - Add trend line

3. **Clustered Bar Chart:**
   - Title: "FSIs per 100k by Cluster"
   - Axis: `fsi_cluster_analysis[regional_cluster]`
   - Values: `fsi_cluster_analysis[fsis_per_100k]`
   - Sort: Descending

4. **Slicer (Left panel):**
   - Regional Cluster
   - Country
   - FSI Count range (slider)

---

### Page 3: Activities & Sharing

**Layout:** Activity and sharing mode analysis

**Visuals:**

1. **Stacked Bar Chart:**
   - Title: "Food Sharing Activities"
   - Axis: `fsi_activity_summary[metric_name]`
   - Values: `fsi_activity_summary[fsi_count]`
   - Filter: `metric_type = "Activity"`
   - Data labels: Show count and percentage

2. **Donut Chart:**
   - Title: "How Food is Shared"
   - Legend: `fsi_activity_summary[metric_name]` (filtered by Sharing Mode)
   - Values: `fsi_activity_summary[fsi_count]`
   - Filter: `metric_type = "Sharing Mode"`

3. **Column Chart:**
   - Title: "Multiple Activities Distribution"
   - Axis: `fsi_activity_summary[metric_name]`
   - Values: `fsi_activity_summary[fsi_count]`
   - Filter: `metric_type = "Activity Distribution"`

4. **KPI Cards:**
   - Most Common Activity
   - Most Common Sharing Mode
   - % with Multiple Activities

---

### Page 4: Hub Cities Comparison

**Layout:** Focus on Milan, Utrecht, Barcelona

**Visuals:**

1. **Clustered Column Chart:**
   - Title: "Hub Cities - 2024 vs 2025"
   - Axis: City (Barcelona, Utrecht, Milan)
   - Values: FSI count (2024 manual, 2025 automated with duplicates, 2026 deduplicated)
   - Legend: Year
   - Note: Requires additional data for 2024/2025 comparison

2. **Table:**
   - Hub city details
   - Activities breakdown per hub city

3. **Text Box:**
   - Explanation: "Hub cities received additional manual mapping in 2024.
   2025 automated mapping identified additional FSIs, many of which were
   long-established but newly visible online."

---

## 5. Visual Formatting

### Theme

**Color Palette (by Regional Cluster):**
- Southern Europe: `#E74C3C` (Red)
- Western Europe: `#3498DB` (Blue)
- Northern Europe: `#1ABC9C` (Teal)
- Eastern Europe: `#F39C12` (Orange)
- Other/Neighbourhood: `#95A5A6` (Gray)

### Fonts
- Titles: **Segoe UI Semibold, 14pt**
- Data labels: **Segoe UI, 10pt**
- KPI numbers: **Segoe UI Bold, 24pt**

### Borders & Background
- Background: Light gray `#F4F4F4`
- Visual borders: Light gray, 1px
- Title alignment: Left

---

## 6. Filters & Slicers

### Global Filters (Apply to all pages)

1. **Regional Cluster** - Multi-select dropdown
2. **Country** - Multi-select dropdown
3. **FSI Count Range** - Slider (0 to max)

### Page-specific Filters

- **Page 2 (City Analysis):** Population range slider
- **Page 4 (Hub Cities):** Fixed filter to show only hub cities

---

## 7. Interactivity Settings

### Cross-filtering

Enable cross-filtering between:
- Map ↔ Bar charts
- Cluster visuals ↔ City table
- Activity charts ↔ City filters

### Drill-through

Create drill-through page for **City Details:**
- Right-click any city → Drill through to detailed page
- Show: FSI list, activities breakdown, sharing modes

---

## 8. Performance Optimization

### Query Reduction

1. Use **DirectQuery** mode for large datasets
2. Or use **Import** mode with incremental refresh

### Aggregations

Pre-aggregate in Snowflake (already done via dbt marts):
✅ City-level aggregation
✅ Cluster-level aggregation
✅ Activity summaries

### Visual Limits

- Limit tables to Top N (20-50 rows)
- Use summary visuals instead of detail where possible

---

## 9. Publishing

### Power BI Service

1. **Publish to Workspace:**
   - File → Publish → Select workspace
   - Share with: CULTIVATE team, stakeholders

2. **Schedule Refresh:**
   - Settings → Scheduled refresh
   - Frequency: Daily (if data updates frequently)
   - Or: On-demand only (for stable datasets)

3. **Row-Level Security (Optional):**
   - If restricting data by city/country
   - Create roles in Power BI Desktop
   - Assign users in Power BI Service

---

## 10. Data Refresh Strategy

### Snowflake → Power BI

**Option 1: Import Mode**
- Faster dashboard performance
- Requires scheduled refresh
- Good for stable datasets

**Option 2: DirectQuery Mode**
- Always up-to-date
- Relies on Snowflake query performance
- Good for frequently updated data

**Recommendation:** Use **Import mode** with manual refresh (data is relatively stable post-deduplication)

---

## 11. Validation Checklist

Before finalizing the dashboard:

- [ ] Total FSIs = 3,052 (matches gold data)
- [ ] Top city: Barcelona with 261 FSIs
- [ ] Regional cluster totals match Snowflake
- [ ] All visuals load without errors
- [ ] Filters work across all pages
- [ ] Colors match regional cluster scheme
- [ ] Data labels are readable
- [ ] Tooltips show relevant information
- [ ] Published version accessible to team

---

## 12. Maintenance

### When to Update

1. **After new data load:** Re-run dbt models → Refresh Power BI
2. **After city population updates:** Update `city_populations` CTE in `fsi_city_summary.sql`
3. **After regional cluster changes:** Update cluster assignments

### Version Control

- Save Power BI file as: `FSI_Landscape_105Cities_v{YYYYMMDD}.pbix`
- Document major changes in this README
- Keep backup of previous versions

---

## 13. Reference Data

### City Population Sources
- Eurostat
- National census data
- City official statistics

### Regional Cluster Definitions
- Based on geographic and cultural-institutional similarities
- Documented in dbt model: `fsi_city_summary.sql`

---

## Troubleshooting

### Common Issues

**Issue:** "Cannot connect to Snowflake"
- **Solution:** Check Snowflake credentials, warehouse is running, network access

**Issue:** "Table not found"
- **Solution:** Run dbt models first: `dbt run --select fsi_city_summary+`

**Issue:** "Visual shows wrong totals"
- **Solution:** Check DAX measure context (CALCULATE vs SUM)

**Issue:** "Map doesn't show cities"
- **Solution:** Ensure city names match Bing Maps geocoding (e.g., "Brighton and Hove" not "Brighton")

---

## Files

**Dashboard File (save as):**
```
exploration/2026/03/FSI_Landscape_105Cities.pbix
```

**Supporting Documentation:**
- This guide: `POWERBI_SETUP.md`
- Data dictionary: `scripts/README.md`
- dbt models: `models/marts/fsi_*.sql`

---

## Next Steps

1. ⏳ Build dashboard following this guide
2. ⏳ Validate against gold data (3,052 FSIs)
3. ⏳ Add drill-through pages for city details
4. ⏳ Publish to Power BI Service
5. ⏳ Share with CULTIVATE team
6. ⏳ Export visuals for final report (Feb 2026)

---

**Questions?** See main exploration README: `exploration/2026/03/scripts/README.md`
