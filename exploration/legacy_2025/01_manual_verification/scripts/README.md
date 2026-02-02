# Manual Verification Workflow (2025/01)

## Overview

This workflow consolidates manual verification results from city-specific Excel files into analysis results.

**Status:** ✅ Completed
**Scale:** 105 cities across 5 automation rounds
**Process:** Manual review of automation results with false positive categorization

## Input Data Structure

The manual verification process uses city-specific Excel files with manual review annotations:

```
data/bronze/false-positive/
├── Dublin_v1.2.0.xlsx              # Sample manual review files
├── Cork_v1.2.0.xlsx
├── Bari_v1.3.0.xlsx
├── Galway-falsepositive.xlsx
├── Limerick-falsepositive.xlsx
├── Palma de Mallorca_v1.2.0.xlsx
└── ...                             # (Sample only - actual project has ~500+ files)

reports/2025_01_manual_verification/
└── manual_verification_results.xlsx  # Compiled results
```

**Note:** Only sample files are tracked in git. Full dataset contains ~500+ city review files.

### Excel File Format

Each city file contains these columns:
- **City, Country, Name**: FSI identification
- **URL, Facebook URL, Twitter URL, Instagram URL**: Contact information
- **Food Sharing Activities**: Type of food sharing
- **How It Is Shared**: Distribution method
- **Date Checked**: Manual review date
- **Comments**: False positive reasoning (empty = Valid FSI)
- **Lat, Lon**: Geolocation
- **review**: Additional categorization notes

## Workflow Steps

### 1. Automation Output (5 Rounds)
- Automation scripts discover potential FSI URLs per city
- Results saved as city-specific Excel files
- **Total:** 105 cities processed across 5 automation rounds (v1.0.0 → v2.0.0)
- **Incremental approach:** Each round automatically filters out previously discovered FSIs
- Only **new FSIs** from each round undergo manual verification

### 2. Manual Review
- Researchers manually review **new** automation results from each round
- Previously verified FSIs are automatically filtered out (no re-verification)
- **Review protocol**: Followed standardized manual review guidance (V02)
- **Valid FSIs**: Leave Comments column empty
- **False Positives**: Add reasoning in Comments column
  - Example: "blog", "Commercial-restaurant", "Dublin Ohio", "page not found"

### 3. Compilation
- Script reads all city files from `data/bronze/false-positive/`
- Categorizes FP based on Comments patterns
- Aggregates statistics per city
- Generates consolidated tracker Excel with:
  - Summary sheet (statistics by city)
  - Valid FSIs sheet (cleaned FSI list)
  - FP Analysis sheet (categorized false positives)
  - All URLs sheet (full detailed data)

## False Positive Categories

Categories are automatically derived from Comments column patterns:

| Category | Pattern Examples | Description |
|----------|-----------------|-------------|
| FP_MEDIA | blog, newspaper, magazine | Media coverage about FSI |
| FP_COMMERCIAL | commercial, restaurant, catering | Commercial food business |
| FP_GOVERNMENT | gov, government, municipality | Government/municipality page |
| FP_WRONG_LOCATION | Dublin California, Dublin Ohio | Wrong geographic location |
| FP_BROKEN_LINK | page not found, 404, broken | Broken or redirected link |
| FP_DUPLICATE | repetition, duplicate, already listed | Duplicate entry |
| FP_NON_FSI_ORG | student accomodation, university | Non-FSI organization |
| FP_SUPPORTING_ORG | supporting organisation | Supporting org (not actual FSI) |
| FP_OTHER | - | Other false positive reasons |

## Output Structure

**manual_verification_results.xlsx** contains:

- **Summary**: Statistics per city (total_checked, valid_fsi, false_positives, accuracy_pct)
- **Valid FSIs**: Clean FSI list for research (city, name, url, activities, lat/lon)
- **FP Analysis**: Breakdown of false positive categories with counts
- **All URLs**: Complete detailed data with all fields

## Usage

To run compilation locally:

```bash
# 1. Ensure manual review files are in data/bronze/false-positive/
ls data/bronze/false-positive/

# 2. Install dependencies
cd exploration/legacy_2025/01/scripts
pip install -r requirements.txt

# 3. Run compilation script
python compile_tracker.py

# 4. Results saved to reports/2025_01_manual_verification/
```

### Example Output

**Note:** This is a sample run with 7 cities. Actual project covers 105 cities across 5 rounds.

```
=== Manual Verification Tracker Compilation ===

Found 7 city review files to process

  Loading Dublin_v1.2.0.xlsx...
  Loading Cork_v1.2.0.xlsx...
  Loading Bari_v1.3.0.xlsx...
  ...

✓ Loaded 458 total URLs from 7 files

Generating summary statistics...
  ✓ Summary for 7 cities
  ✓ Total Valid FSIs: 312
  ✓ Total False Positives: 146

Analyzing false positive patterns...
  ✓ Categorized into 8 FP types

✅ Compilation complete!
   Output: reports/2025_01_manual_verification/manual_verification_results.xlsx
   Total URLs checked: 458
   Valid FSIs: 312 (68.1%)
   False Positives: 146 (31.9%)
   Cities covered: 7
```

**Full Project Scale:**
- 105 cities total (Dublin, Rome, Barcelona, Seoul, etc.)
- 5 automation rounds (v1.0.0, v1.1.0, v1.2.0, v1.3.0, v2.0.0)
- ~500+ city-specific review files
- Thousands of URLs manually verified

## Project Scale

- **Cities:** 105 cities globally (Dublin, Rome, Barcelona, Seoul, Amsterdam, etc.)
- **Rounds:** 5 automation rounds (v1.0.0 → v2.0.0)
- **Approach:** Incremental verification - only new FSIs per round
- **Files:** ~500+ city-specific review Excel files across all rounds
- **URLs:** Thousands of URLs manually verified (new discoveries only, no duplicates)
- **Timeline:** Multi-month manual verification effort

## Notes

- **Sample data only**: Repository contains only sample review files for demonstration
- **Full dataset**: ~500+ files not tracked in git (too large, contain sensitive URLs)
- **Incremental verification**: Each round only verifies new FSIs (auto-deduplication)
- **Standardized protocol**: Manual review followed documented guidance (V02) for consistency
- **Results in reports**: Compiled results saved to `reports/2025_01_manual_verification/` (gitignored)
- **Manual process**: Primarily manual review work with light scripting for compilation
- **Portfolio focus**: See [2025/02 - Automation Improvement](../../02/scripts/) for automated prompt engineering work

## Related Tests

- **[2025/02 - Automation Improvement](../../../2025/02/scripts/)**: Improved automation accuracy from 32% → 69.6%
- **[2026/01 - Duplication Check](../../../2026/01/)**: Automated deduplication of 2024 data
