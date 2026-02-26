-- ============================================================================
-- Bronze Layer: ShareCity200 Pre-Deduplication Data
-- ============================================================================
-- Purpose: Load ShareCity200 export (pre-deduplication) for comparison analysis
-- Source: data/bronze/duplication/sharecity200-export-1768225380870.csv
-- Expected rows: 3,140 FSIs
-- ============================================================================

USE DATABASE CULTIVATE;
USE SCHEMA HC_LOAD_DATA_FROM_CLOUD;

-- Create comparison input table
CREATE TABLE IF NOT EXISTS gold_fsi_200226 (
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
    -- Metadata
    _loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Load data from Azure stage
-- Note: File uploaded to Azure container 'data' at bronze/duplication/
COPY INTO gold_fsi_200226 (
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
    comments
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
SELECT COUNT(*) as total_rows FROM gold_fsi_200226;
-- Expected: 3,140 rows

SELECT
    country,
    city,
    COUNT(*) as fsi_count
FROM gold_fsi_200226
GROUP BY country, city
ORDER BY fsi_count DESC
LIMIT 20;
-- Top city should be Barcelona

-- Check for any load errors
SELECT * FROM TABLE(VALIDATE(gold_fsi_200226, JOB_ID => '_last'));
