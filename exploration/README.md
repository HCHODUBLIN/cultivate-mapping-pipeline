# Analysis Tests Overview

This directory contains structured analysis tests and experiments used to evaluate, validate, and improve the CULTIVATE mapping pipeline.

## Directory Structure

```
exploration/
├── legacy_2024/ # Original 2024 analysis scripts
├── legacy_2025/ # Completed 2025 analysis work
│ ├── 01_manual_verification/ # Manual Verification (Jan 2025)
│ └── 02_automation_improvement/ # Automation Improvement (Feb 2025)
├── 2026/ # Ongoing 2026 analysis work
│ ├── 01_duplication/ # Duplication Check (Jan 2026) - Completed
│ ├── 02_query_design/ # Query Design Improvements (Feb 2026) - In Progress
│ └── 03_landscape_analysis/ # FSI Landscape Analysis (Mar 2026)
```

**Note:**

- **Scripts only** – Analysis folders contain scripts and documentation only (no raw data)
- **Data** - Test data lives in `/data/bronze/` (not tracked in git)
- **Results** - All outputs go to `/reports/` (not tracked in git)

---

## Test Catalog

### 2024 Tests

#### Pipeline Evaluation

- **Status:** Completed
- **Location:** `legacy_2024/`
- **Description:** Domain-level and similarity-based matching for recall/precision evaluation

---

### 2025 Tests

#### 01 - Manual Verification

- **Status:** ✅ Completed
- **Purpose:** Compile manual verification results from city-specific review files
- **Scale:** 105 cities across five automation rounds (incremental: new FSIs only)
- **Description:** Manual review of automation results with false-positive categorisation
- **Results:** `reports/2025_01_manual_verification/` (gitignored)
- **Note:** Sample files in repo; full dataset (~500+ files) not tracked due to size

#### 02 - Automation Improvement (Prompt Engineering & Agent-Based Classification)

- **Status:** ✅ Completed
- **Purpose:** Improve FSI classification accuracy through prompt engineering and an agent-based approach
- **GitHub:** https://github.com/HCHODUBLIN/CULTIVATE_2nd_Filtering
- **Key Findings:**
  - Original automation (chat-based): 32.02% accuracy (73/228 validated FSIs)
  - 2nd filtering (27 Oct): 68.87% accuracy (73/106)
  - Improved prompt (3 Nov): 69.6% accuracy (73/89)
  - **Agent-based approach: 74% accuracy** (+42% from baseline, manual validation)
- **Technical Improvements:**
  - Migrated from chat-based to agent-based classification
  - Eliminated manual HTML scraping (reduced server costs)
  - Agent with web search capability fetches content autonomously
  - Multi-agent architecture: Web Content Extractor + FSI Classifier
- **Approach:**
  1. Iterative prompt refinement based on false positives/negatives
  2. Added exclusion rules for museums, crowdfunding platforms, media sites
  3. Implemented agent-based classification with GPT-4o
  4. Modular architecture for improved scalability

---

### 2026 Tests

#### 01 - Duplication Check

- **Status:** ✅ Completed
- **Purpose:** Detect and remove duplicates from ShareCity 200 dataset
- **Script:** `detect_duplicates.py` - Multi-strategy deduplication (exact, URL, fuzzy)
- **Strategies:**
  - Exact matching on normalized country+city+name
  - URL-based detection with normalization
  - Fuzzy name matching (92% similarity threshold)
- **Results:**
  - Pre-deduplication: 3,140 FSIs
  - Post-deduplication: 3,052 FSIs
  - Duplicates removed: 88 FSIs (2.8% deduplication rate)
- **Snowflake Integration:** Bronze table and comparison queries available
- **Documentation:** See [2026/01_duplication/scripts/README.md](2026/01_duplication/scripts/README.md)

#### 02 - Query Design Improvements

- **Status:** 🟡 In Progress
- **Purpose:** Improve search query design for geolocation filtering and city name disambiguation
- **Problem:** Same city names across countries (Dublin, Ireland vs Dublin, USA)
- **Solutions:**
  - Google API country parameter filtering
  - Geolocation boundary validation
  - Query refinement (append country to city names)
- **Documentation:** See [2026/02_query_design/scripts/README.md](2026/02_query_design/scripts/README.md)

#### 03 - FSI Landscape Analysis (105 Cities)

- **Status:** 🟡 In Progress
- **Purpose:** Analyze final deduplicated FSI dataset across 105 European cities
- **Data Source:** Gold layer (3,052 FSIs post-deduplication)
- **Components:**
  - dbt mart models: city summary, cluster analysis, activity breakdown
  - Power BI dashboard design
  - Pre vs post-deduplication comparison
  - Snowflake data warehouse integration
- **Key Outputs:**
  - City-level FSI statistics with population metrics
  - Regional cluster analysis (Southern, Western, Northern, Eastern Europe)
  - Deduplication impact report (3,140 → 3,052 FSIs, 88 duplicates removed)
- **Documentation:** See [2026/03_landscape_analysis/scripts/README.md](2026/03_landscape_analysis/scripts/README.md)

---
