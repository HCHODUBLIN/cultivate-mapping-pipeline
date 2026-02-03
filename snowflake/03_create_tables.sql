-- 03_create_tables.sql
-- Create raw landing tables for CULTIVATE mapping pipeline

-- 1) Automation candidates (CSV)
CREATE OR REPLACE TABLE raw_automation (
  automation_id STRING,
  city          STRING,
  run_id        STRING,
  source_url    STRING,
  file_name     STRING,
  loaded_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 2) Automation reviewed decisions (CSV)
-- Store is_included as STRING in raw; cast to BOOLEAN downstream in dbt.
CREATE OR REPLACE TABLE raw_automation_reviewed (
  automation_id STRING,
  is_included   STRING,
  file_name     STRING,
  loaded_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3) City language lookup (CSV)
CREATE OR REPLACE TABLE raw_city_language (
  city            STRING,
  search_language STRING,
  file_name       STRING,
  loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 4) Ground truth URLs (CSV)
CREATE OR REPLACE TABLE raw_ground_truth (
  ground_truth_id STRING,
  city            STRING,
  source_url      STRING,
  file_name       STRING,
  loaded_at       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 5) Cultivate 2026 outputs (JSON)
CREATE OR REPLACE TABLE raw_cultivate_api (
  raw_json  VARIANT,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 6) Power BI export (CSV, loaded via 07_powerbi_export.sql MERGE)
CREATE TABLE IF NOT EXISTS MART_FSI_POWERBI_EXPORT (
    id                      STRING,
    city                    STRING,
    country                 STRING,
    name                    STRING,
    url                     STRING,
    facebook_url            STRING,
    twitter_url             STRING,
    instagram_url           STRING,
    food_sharing_activities STRING,
    how_it_is_shared        STRING,
    date_checked            STRING,
    lat                     FLOAT,
    lon                     FLOAT,
    round                   STRING,
    growing                 INTEGER,
    distribution            INTEGER,
    cooking_eating          INTEGER,
    gifting                 INTEGER,
    collecting              INTEGER,
    selling                 INTEGER,
    bartering               INTEGER
);

-- 7) ShareCity200 pre-deduplication data (CSV) - Analysis
CREATE OR REPLACE TABLE bronze_sharecity200_raw (
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
    date_modified TIMESTAMP,
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

