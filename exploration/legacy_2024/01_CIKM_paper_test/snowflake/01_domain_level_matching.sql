-- 08_analysis.sql
-- Analysis queries for CULTIVATE mapping pipeline
-- Measures recall (ground_truth coverage) and precision (automation quality)
-- IMPORTANT: Uses DOMAIN-LEVEL matching (domain column from staging tables)

-- ============================================================
-- 1) RECALL: How many ground_truth URLs were found by automation?
-- ============================================================

CREATE OR REPLACE VIEW v_recall_by_city_language AS
WITH
  -- Ground truth with language
  gt_with_lang AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.source_url,
      gt.domain,
      cl.search_language
    FROM stg_ground_truth gt
    LEFT JOIN stg_city_language cl ON gt.city = cl.city
  ),

  -- Check if each ground_truth URL was found in automation (using DOMAIN-LEVEL matching)
  gt_matched AS (
    SELECT
      gt.city,
      gt.search_language,
      gt.ground_truth_id,
      gt.source_url,
      gt.domain,
      CASE WHEN a.domain IS NOT NULL THEN 1 ELSE 0 END AS found_in_automation
    FROM gt_with_lang gt
    LEFT JOIN stg_automation a
      ON gt.domain = a.domain
      AND gt.city = a.city
  )

SELECT
  city,
  search_language,
  COUNT(DISTINCT ground_truth_id) AS total_ground_truth,
  SUM(found_in_automation) AS found_by_automation,
  ROUND(SUM(found_in_automation) * 100.0 / NULLIF(COUNT(DISTINCT ground_truth_id), 0), 2) AS recall_percent
FROM gt_matched
GROUP BY city, search_language
ORDER BY city, search_language;


-- ============================================================
-- 2) PRECISION: What % of automation results are correct (is_included=TRUE)?
-- ============================================================

CREATE OR REPLACE VIEW v_precision_by_city_language AS
WITH
  -- Automation results with review status
  auto_with_review AS (
    SELECT
      a.automation_id,
      a.city,
      a.run_id,
      a.version,
      a.source_url,
      a.source_url_norm,
      cl.search_language,
      COALESCE(r.is_included, FALSE) AS is_included
    FROM stg_automation a
    LEFT JOIN stg_automation_review r ON a.automation_id = r.automation_id
    LEFT JOIN stg_city_language cl ON a.city = cl.city
  )

SELECT
  city,
  search_language,
  version,
  COUNT(*) AS total_automation_results,
  SUM(CASE WHEN is_included THEN 1 ELSE 0 END) AS correct_results,
  ROUND(SUM(CASE WHEN is_included THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS precision_percent
FROM auto_with_review
GROUP BY city, search_language, version
ORDER BY city, search_language, version;


-- ============================================================
-- 3) COMBINED METRICS: Recall + Precision by Language
-- ============================================================

CREATE OR REPLACE VIEW v_metrics_by_language AS
WITH
  recall_lang AS (
    SELECT
      search_language,
      SUM(found_by_automation) AS total_found,
      SUM(total_ground_truth) AS total_gt,
      ROUND(SUM(found_by_automation) * 100.0 / NULLIF(SUM(total_ground_truth), 0), 2) AS recall_percent
    FROM v_recall_by_city_language
    GROUP BY search_language
  ),

  precision_lang AS (
    SELECT
      search_language,
      SUM(correct_results) AS total_correct,
      SUM(total_automation_results) AS total_auto,
      ROUND(SUM(correct_results) * 100.0 / NULLIF(SUM(total_automation_results), 0), 2) AS precision_percent
    FROM v_precision_by_city_language
    GROUP BY search_language
  )

SELECT
  COALESCE(r.search_language, p.search_language) AS search_language,
  r.total_gt AS ground_truth_count,
  r.total_found AS found_by_automation,
  r.recall_percent,
  p.total_auto AS automation_results,
  p.total_correct AS correct_results,
  p.precision_percent,
  -- F1 score (harmonic mean of precision and recall)
  CASE
    WHEN r.recall_percent > 0 AND p.precision_percent > 0
    THEN ROUND(2 * (r.recall_percent * p.precision_percent) / (r.recall_percent + p.precision_percent), 2)
    ELSE 0
  END AS f1_score
FROM recall_lang r
FULL OUTER JOIN precision_lang p ON r.search_language = p.search_language
ORDER BY search_language;


-- ============================================================
-- 4) COMBINED METRICS: Recall + Precision by Version
-- ============================================================

CREATE OR REPLACE VIEW v_metrics_by_version AS
WITH
  -- Recall doesn't vary by version, but we'll join it for completeness
  precision_ver AS (
    SELECT
      version,
      SUM(correct_results) AS total_correct,
      SUM(total_automation_results) AS total_auto,
      ROUND(SUM(correct_results) * 100.0 / NULLIF(SUM(total_automation_results), 0), 2) AS precision_percent
    FROM v_precision_by_city_language
    GROUP BY version
  )

SELECT
  version,
  total_auto AS automation_results,
  total_correct AS correct_results,
  precision_percent
FROM precision_ver
ORDER BY version;


-- ============================================================
-- 5) DETAILED BREAKDOWN: City x Language x Version
-- ============================================================

CREATE OR REPLACE VIEW v_metrics_detailed AS
WITH
  recall_detail AS (
    SELECT
      city,
      search_language,
      total_ground_truth,
      found_by_automation,
      recall_percent
    FROM v_recall_by_city_language
  ),

  precision_detail AS (
    SELECT
      city,
      search_language,
      version,
      total_automation_results,
      correct_results,
      precision_percent
    FROM v_precision_by_city_language
  )

SELECT
  COALESCE(r.city, p.city) AS city,
  COALESCE(r.search_language, p.search_language) AS search_language,
  p.version,
  r.total_ground_truth,
  r.found_by_automation,
  r.recall_percent,
  p.total_automation_results,
  p.correct_results,
  p.precision_percent,
  -- F1 score
  CASE
    WHEN r.recall_percent > 0 AND p.precision_percent > 0
    THEN ROUND(2 * (r.recall_percent * p.precision_percent) / (r.recall_percent + p.precision_percent), 2)
    ELSE 0
  END AS f1_score
FROM recall_detail r
FULL OUTER JOIN precision_detail p
  ON r.city = p.city
  AND r.search_language = p.search_language
ORDER BY city, search_language, version;


-- ============================================================
-- 6) MISSING URLs: Ground truth URLs NOT found by automation
-- ============================================================

CREATE OR REPLACE VIEW v_missing_ground_truth AS
WITH
  gt_with_lang AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.source_url,
      gt.domain,
      cl.search_language
    FROM stg_ground_truth gt
    LEFT JOIN stg_city_language cl ON gt.city = cl.city
  )

SELECT
  gt.ground_truth_id,
  gt.city,
  gt.search_language,
  gt.source_url,
  gt.domain
FROM gt_with_lang gt
LEFT JOIN stg_automation a
  ON gt.domain = a.domain
  AND gt.city = a.city
WHERE a.domain IS NULL
ORDER BY gt.city, gt.ground_truth_id;


-- ============================================================
-- 7) FALSE POSITIVES: Automation results marked as is_included=FALSE
-- ============================================================

CREATE OR REPLACE VIEW v_false_positives AS
WITH
  auto_with_lang AS (
    SELECT
      a.automation_id,
      a.city,
      a.run_id,
      a.version,
      a.source_url,
      a.source_url_norm,
      cl.search_language,
      r.is_included
    FROM stg_automation a
    JOIN stg_automation_review r ON a.automation_id = r.automation_id
    LEFT JOIN stg_city_language cl ON a.city = cl.city
    WHERE r.is_included = FALSE
  )

SELECT
  automation_id,
  city,
  search_language,
  run_id,
  version,
  source_url,
  source_url_norm
FROM auto_with_lang
ORDER BY city, run_id, automation_id;


-- ============================================================
-- 8) URL NORMALIZATION TEST: Check if normalization is working
-- ============================================================

CREATE OR REPLACE VIEW v_url_normalization_test AS
SELECT
  'ground_truth' as source_table,
  ground_truth_id as id,
  city,
  source_url as original_url,
  source_url_norm as normalized_url
FROM stg_ground_truth
UNION ALL
SELECT
  'automation' as source_table,
  automation_id as id,
  city,
  source_url as original_url,
  source_url_norm as normalized_url
FROM stg_automation
ORDER BY source_table, city, id;


-- ============================================================
-- USAGE EXAMPLES:
-- ============================================================

-- View overall metrics by language
-- SELECT * FROM v_metrics_by_language;

-- View metrics by version
-- SELECT * FROM v_metrics_by_version;

-- View detailed breakdown by city/language/version
-- SELECT * FROM v_metrics_detailed;

-- Find missing ground truth URLs
-- SELECT * FROM v_missing_ground_truth;

-- Find false positives
-- SELECT * FROM v_false_positives;

-- Test URL normalization
-- SELECT * FROM v_url_normalization_test WHERE city = 'cork' LIMIT 20;
