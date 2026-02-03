-- ============================================================
-- 08: STG_FSI_POWERBI_EXPORT (Silver)
-- Parses date_checked STRING → DATE with safe fallback.
-- Adds is_recent flag: TRUE if date_checked = today (new record).
-- Source: MART_FSI_POWERBI_EXPORT (07_powerbi_export.sql)
-- ============================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE VIEW STG_FSI_POWERBI_EXPORT AS
SELECT
    TRY_CAST(id AS INTEGER)                         AS id,
    city,
    country,
    name,
    url,
    facebook_url,
    twitter_url,
    instagram_url,
    food_sharing_activities,
    how_it_is_shared,

    -- Safe date parsing → TIMESTAMP for Azure SQL datetime
    COALESCE(
        TRY_TO_DATE(date_checked, 'DD/MM/YYYY'),
        TRY_TO_DATE(date_checked, 'YYYY-MM-DD'),
        TRY_TO_DATE(date_checked, 'MM/DD/YYYY')
    )::TIMESTAMP_NTZ                                AS date_checked,

    -- QA flag: true if raw value exists but parsing failed
    CASE
        WHEN date_checked IS NOT NULL
         AND COALESCE(
                TRY_TO_DATE(date_checked, 'DD/MM/YYYY'),
                TRY_TO_DATE(date_checked, 'YYYY-MM-DD'),
                TRY_TO_DATE(date_checked, 'MM/DD/YYYY')
             ) IS NULL
        THEN TRUE
        ELSE FALSE
    END                                             AS date_parse_failed,

    -- Tracking: TRUE if this record was added/checked today
    CASE
        WHEN COALESCE(
                TRY_TO_DATE(date_checked, 'DD/MM/YYYY'),
                TRY_TO_DATE(date_checked, 'YYYY-MM-DD'),
                TRY_TO_DATE(date_checked, 'MM/DD/YYYY')
             ) = CURRENT_DATE()
        THEN TRUE
        ELSE FALSE
    END                                             AS is_recent,

    lat::NUMBER(10,7)                               AS lat,
    lon::NUMBER(10,7)                               AS lon,
    round,
    growing     = 1                                 AS growing,
    distribution = 1                                AS distribution,
    cooking_eating = 1                              AS cooking_eating,
    gifting     = 1                                 AS gifting,
    collecting  = 1                                 AS collecting,
    selling     = 1                                 AS selling,
    bartering   = 1                                 AS bartering
FROM MART_FSI_POWERBI_EXPORT;

-- Validate
SELECT COUNT(*) AS total_rows FROM STG_FSI_POWERBI_EXPORT;
SELECT COUNT(*) AS failed_dates FROM STG_FSI_POWERBI_EXPORT WHERE date_parse_failed = TRUE;
SELECT COUNT(*) AS recent_records FROM STG_FSI_POWERBI_EXPORT WHERE is_recent = TRUE;
