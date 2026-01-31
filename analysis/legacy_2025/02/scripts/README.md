# Automation Improvement - Prompt Engineering & Agent-Based Classification (2025/02)

## Overview

**Status:** ✅ Completed
**Purpose:** Improve FSI classification accuracy through iterative prompt engineering and agent-based approach
**GitHub:** https://github.com/HCHODUBLIN/CULTIVATE_2nd_Filtering

## Key Results

- **Original automation (chat-based):** 32.02% accuracy (73/228 validated FSIs)
- **2nd filtering (27 Oct):** 68.87% accuracy (73/106)
- **Improved prompt (3 Nov):** 69.6% accuracy (73/89)
- **Agent-based approach:** 74% accuracy (+42% from baseline)

## Approach Comparison

### Current Model (Text Scraping + GPT Classification)

**Workflow:**
1. Scrape text from URLs and save locally
2. Send scraped text to GPT-4o-mini for classification
3. Apply 2nd filtering with improved prompt
4. Store scraped text files

**Limitations:**
- Requires text scraping infrastructure
- Storage overhead for scraped text
- Slower processing (scraping + classification)

### Agent-Based LLM Model (Recommended)

**Workflow:**
1. Send URLs directly to GPT agent with web_search tool
2. Agent autonomously fetches and analyzes content
3. Single-step classification decision
4. No text storage needed

**Benefits:**
- Eliminates text scraping (reduces server costs)
- Agent can research multiple pages (About, Projects, etc.)
- No storage needed for scraped text
- Faster processing
- Higher accuracy

## Performance Comparison

| Model | Accuracy | Cost (228 URLs) | Time (228 URLs) | Notes |
|-------|----------|-----------------|-----------------|-------|
| **Current (gpt-4o-mini)** | 69.6% | $0.65 | 25-30 min | Text scraping (15-20 min) + 2nd filtering (10 min) |
| **Agent-based (gpt-4o-mini)** | 74% | $0.82 | ~5 min | Single-pass classification, no scraping |
| **Agent-based (gpt-4o-nano)** | 69.29% | $0.37 | ~5 min | Lower cost option |

**Trade-offs:**
- Agent-based: +27% faster, +4.4% more accurate, +26% more expensive
- Cost increase offset by eliminated storage costs

## Technical Improvements

1. **Iterative prompt refinement** based on false positives/negatives
2. **Exclusion rules** for museums, crowdfunding platforms, media sites
3. **Multi-agent architecture:** Web Content Extractor + FSI Classifier
4. **Modular design** for improved scalability

## Pipeline

### Current Model (Text Scraping)
```bash
# 1. Scrape URLs and save text
python 2ndfiltering.py

# 2. Classify FSI with improved prompt
python analyse_fsi_filter_improved.py

# 3. Build final dataset
python build_fsi_included_dataset.py
```

### Utility Scripts
- `Json_to_xlsx.py` - Convert JSON outputs to Excel
- `merge_excels.py` - Merge multiple Excel files
- `count_entries.py` - Count entries in datasets
- `quick_test_openai.py` - Quick OpenAI API test

## Setup

**Python environment:**
```bash
cd analysis/legacy_2025/02/scripts
pip install -r requirements.txt
```

**Environment variables:**
```bash
export OPENAI_API_KEY="sk-your-key-here"
# Or use .env file (see root .env.example)
```

## Data

**Inputs:**
- `Run-03/01--to-process/*.xlsx` - URLs to process

**Outputs:**
- `Run-03/01--to-process/_scraped_text/` - Scraped text files (current model)
- `Run-03/*.csv` - Classification results
- `Run-03/*.xlsx` - Final datasets

## Migration to Agent-Based Model

The agent-based approach is recommended for future implementations:
- Reduces infrastructure complexity (no scraping servers)
- Eliminates storage overhead
- Improves accuracy
- Faster processing

See [DESIGN_DECISIONS.md](../../../../DESIGN_DECISIONS.md) for architectural rationale.
