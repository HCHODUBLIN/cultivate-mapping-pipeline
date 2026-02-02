# Duplication Detection (2026/01)

## Overview

Comprehensive deduplication analysis for ShareCity 200 dataset using multiple detection strategies.

**Status:** ✅ Completed
**Purpose:** Detect and remove duplicates from 2024 automation data
**Dataset:** ShareCity 200 export (sharecity200-export-1768225380870.csv)

## Detection Strategies

### 1. Exact Duplicate Detection
- **Key:** `country + city + name` (normalized)
- **Method:** Text normalization + exact matching
- **Output:** `duplicates_sharecity_by_key.csv`

### 2. URL-Based Duplicate Detection
- **Key:** `country + city + normalized_url`
- **Normalization:** Removes http/https, www, query parameters, fragments
- **Output:** `duplicates_sharecity_by_city_country_url.csv`

### 3. Fuzzy Name Matching
- **Algorithm:** SequenceMatcher (difflib)
- **Threshold:** 92% similarity
- **Scope:** Within same country + city
- **Output:** `near_duplicates_sharecity_fuzzy.csv`

## Text Normalization

All text fields are normalized using:
- **Unicode:** NFKC normalization
- **Case:** Casefolded (locale-aware lowercase)
- **Whitespace:** Collapsed to single spaces
- **Special chars:** Quotes normalized, non-alphanumeric removed

## Usage

```bash
# 1. Ensure input data is in data/bronze/
ls data/bronze/sharecity200-export-1768225380870.csv

# 2. Run deduplication script
cd exploration/2026/01/scripts
python detect_duplicates.py

# 3. Review outputs
ls *.csv
#   - duplicates_sharecity_by_key.csv
#   - duplicates_sharecity_by_city_country_url.csv
#   - near_duplicates_sharecity_fuzzy.csv
```

## Output Format

### Exact Duplicates (`duplicates_sharecity_by_key.csv`)
Contains all rows that share the same normalized `country + city + name` key, sorted by match_key.

### URL Duplicates (`duplicates_sharecity_by_city_country_url.csv`)
Contains rows with duplicate URLs within the same city+country, showing both the original and normalized URLs.

### Fuzzy Matches (`near_duplicates_sharecity_fuzzy.csv`)
Pairs of entries with similar (≥92%) names within the same city:
- `name_i`, `name_j`: Original names being compared
- `similarity`: Similarity score (0.92-1.0)
- `row_i`, `row_j`: Row indices in original data

## Configuration

Key parameters in `detect_duplicates.py`:

```python
FUZZY_THRESHOLD = 0.92           # Similarity threshold (92%)
MAX_GROUP_SIZE = 400             # Skip cities with >400 entries (performance)
MAX_RESULTS_PER_GROUP = 200      # Limit results per city
```

## Dependencies

```bash
pip install pandas
# Standard library: re, pathlib, unicodedata, difflib
```

## Notes

- **Performance:** Fuzzy matching is O(n²) per city, limited by MAX_GROUP_SIZE
- **Unicode:** Handles multilingual text (European cities)
- **Case-insensitive:** All comparisons use casefolded text
- **URL normalization:** Focuses on domain/path, ignores params/fragments
