-- ============================================================================
-- Bronze Layer: ShareCity200 Pre-Deduplication Data
-- ============================================================================
-- Purpose: Load ShareCity200 export (pre-deduplication) for comparison analysis
-- Source: data/bronze/duplication/sharecity200-export-1768225380870.csv
-- Expected rows: 3,140 FSIs
-- ============================================================================

USE DATABASE cultivate_db;
USE SCHEMA public;

-- Create bronze table for pre-deduplication data
CREATE TABLE IF NOT EXISTS bronze_sharecity200_raw (
    country VARCHAR,
    city VARCHAR,
    name VARCHAR,
    url VARCHAR,
    instagram_url VARCHAR,
    twitter_url VARCHAR,
    facebook_url VARCHAR,
    food_sharing_activities VARCHAR,  -- JSON array as string
    how_it_is_shared VARCHAR,          -- JSON array as string
    lon FLOAT,
    lat FLOAT,
    comments VARCHAR,
    date_checked VARCHAR,
    date_modified TIMESTAMP,
    -- Metadata
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Load data from Azure stage
-- Note: File uploaded to Azure container 'data' at bronze/duplication/
COPY INTO bronze_sharecity200_raw (
    country,
    city,
    name,
    url,
    instagram_url,
    twitter_url,
    facebook_url,
    food_sharing_activities,
    how_it_is_shared,
    lon,
    lat,
    comments,
    date_checked,
    date_modified
)
FROM @stg_azure_raw/bronze/duplication/sharecity200-export-1768225380870.csv
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ENCODING = 'UTF8'
    EMPTY_FIELD_AS_NULL = TRUE
)
ON_ERROR = 'CONTINUE';

-- Validation queries
SELECT COUNT(*) as total_rows FROM bronze_sharecity200_raw;
-- Expected: 3,140 rows

SELECT
    country,
    city,
    COUNT(*) as fsi_count
FROM bronze_sharecity200_raw
GROUP BY country, city
ORDER BY fsi_count DESC
LIMIT 20;
-- Top city should be Barcelona

-- Check for any load errors
SELECT * FROM TABLE(VALIDATE(bronze_sharecity200_raw, JOB_ID => '_last'));
