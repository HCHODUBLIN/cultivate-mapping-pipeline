-- ============================================================================
-- Deduplication Comparison Query (Standalone)
-- ============================================================================
-- Purpose: Compare pre-deduplication vs post-deduplication FSI counts
-- Can run directly in Snowflake without dbt
-- ============================================================================

USE DATABASE cultivate_db;
USE SCHEMA public;

-- Overall Summary
SELECT
    'TOTAL' as comparison_level,
    COUNT(DISTINCT b.name) as fsi_count_before,
    COUNT(DISTINCT g.name) as fsi_count_after,
    COUNT(DISTINCT b.name) - COUNT(DISTINCT g.name) as duplicates_removed,
    ROUND((COUNT(DISTINCT b.name) - COUNT(DISTINCT g.name)) * 100.0 / COUNT(DISTINCT b.name), 2) as dedup_rate_pct
FROM bronze_sharecity200_raw b
FULL OUTER JOIN gold_fsi_final g ON 1=1;

-- City-level comparison
WITH pre_dedup AS (
    SELECT
        city,
        country,
        COUNT(*) as fsi_count_before
    FROM bronze_sharecity200_raw
    GROUP BY city, country
),
post_dedup AS (
    SELECT
        city,
        country,
        COUNT(*) as fsi_count_after
    FROM gold_fsi_final
    GROUP BY city, country
)
SELECT
    COALESCE(pre.city, post.city) as city,
    COALESCE(pre.country, post.country) as country,
    COALESCE(pre.fsi_count_before, 0) as fsi_count_before,
    COALESCE(post.fsi_count_after, 0) as fsi_count_after,
    COALESCE(pre.fsi_count_before, 0) - COALESCE(post.fsi_count_after, 0) as duplicates_removed,
    CASE
        WHEN pre.fsi_count_before > 0
        THEN ROUND((COALESCE(pre.fsi_count_before, 0) - COALESCE(post.fsi_count_after, 0)) * 100.0 / pre.fsi_count_before, 2)
        ELSE 0
    END as dedup_rate_pct,
    CASE
        WHEN pre.fsi_count_before IS NULL THEN 'Added in final'
        WHEN post.fsi_count_after IS NULL THEN 'Removed entirely'
        WHEN pre.fsi_count_before = post.fsi_count_after THEN 'No duplicates'
        ELSE 'Duplicates found'
    END as status
FROM pre_dedup pre
FULL OUTER JOIN post_dedup post
    ON pre.city = post.city
    AND pre.country = post.country
ORDER BY duplicates_removed DESC NULLS LAST;

-- Top 10 cities with most duplicates
WITH pre_dedup AS (
    SELECT city, country, COUNT(*) as fsi_count_before
    FROM bronze_sharecity200_raw
    GROUP BY city, country
),
post_dedup AS (
    SELECT city, country, COUNT(*) as fsi_count_after
    FROM gold_fsi_final
    GROUP BY city, country
)
SELECT
    COALESCE(pre.city, post.city) as city,
    COALESCE(pre.country, post.country) as country,
    COALESCE(pre.fsi_count_before, 0) as before_dedup,
    COALESCE(post.fsi_count_after, 0) as after_dedup,
    COALESCE(pre.fsi_count_before, 0) - COALESCE(post.fsi_count_after, 0) as duplicates_removed
FROM pre_dedup pre
FULL OUTER JOIN post_dedup post
    ON pre.city = post.city
    AND pre.country = post.country
WHERE COALESCE(pre.fsi_count_before, 0) - COALESCE(post.fsi_count_after, 0) > 0
ORDER BY duplicates_removed DESC
LIMIT 10;

-- Cities with no duplicates (perfect data quality)
WITH pre_dedup AS (
    SELECT city, country, COUNT(*) as fsi_count_before
    FROM bronze_sharecity200_raw
    GROUP BY city, country
),
post_dedup AS (
    SELECT city, country, COUNT(*) as fsi_count_after
    FROM gold_fsi_final
    GROUP BY city, country
)
SELECT
    COALESCE(pre.city, post.city) as city,
    COALESCE(pre.country, post.country) as country,
    COALESCE(pre.fsi_count_before, 0) as fsi_count
FROM pre_dedup pre
FULL OUTER JOIN post_dedup post
    ON pre.city = post.city
    AND pre.country = post.country
WHERE COALESCE(pre.fsi_count_before, 0) = COALESCE(post.fsi_count_after, 0)
  AND COALESCE(pre.fsi_count_before, 0) > 0
ORDER BY fsi_count DESC;
