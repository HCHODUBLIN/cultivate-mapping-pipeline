# Query Design Improvements (2026/02)

## Overview

**Status:** 🟡 In Progress
**Purpose:** Improve search query design to address geolocation filtering and city name disambiguation

## Problem Statement

### City Name Ambiguity
- Same city names across different countries (e.g., Dublin, Ireland vs Dublin, USA)
- Current queries return results from incorrect geographic locations
- Need to filter results by country/region boundaries

### False Positives from Location Mismatch
- FSIs located outside target countries with no specific geolocation details
- Geolocation boundaries not properly enforced in search queries

## Proposed Solutions

### 1. Google API Country Parameter
- Use country filter in Google search API
- Filter: pages from specific country (e.g., "pages from Ireland")
- Test baseline: `Dublin, Ireland + food sharing terms`

### 2. Geolocation Boundaries
- Filter results by latitude/longitude boundaries
- Define country/region polygons
- Exclude results outside boundaries

### 3. Query Refinement
- Append country name to city queries: `"Dublin, Ireland"` instead of `"Dublin"`
- Test different query formats for effectiveness

## Testing Plan

1. **Baseline test**: Dublin, Ireland + terms (Complete)
2. **Filter analysis**: Test each filter option (Complete)
3. **International FSI check**: Verify international FSIs are properly filtered
4. **Integration**: Integrate into automation tool

## Expected Outcomes

- Reduced false positives from location mismatches
- More accurate city-level results
- Better handling of cities with duplicate names across countries

## Data & Scripts

**Note:** Scripts and analysis results will be added as work progresses.

**Test cities:**
- Dublin (Ireland vs USA)
- Other ambiguous city names

## Dependencies

- Google Search API with country parameter support
- Geolocation validation logic
- Updated automation tool integration

## Next Steps

1. Complete international FSI filtering analysis
2. Implement country parameter in search queries
3. Test with multiple cities with name conflicts
4. Document results and integrate into automation tool
5. Update main automation codebase with improvements

---

**Related Work:**
- See [analysis issue tracker](../../legacy_2025/) for historical context
- Duplication detection: [../01/scripts/](../01/scripts/)
