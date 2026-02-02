-- 09_similarity_matching.sql
-- Multi-level URL matching analysis for CULTIVATE mapping pipeline
-- Provides different confidence levels for manual review

-- ============================================================
-- 1) MULTI-LEVEL MATCHES: All possible matches with confidence levels
-- ============================================================

CREATE OR REPLACE VIEW v_url_matches_all_levels AS
WITH
  gt_enhanced AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.source_url,
      gt.source_url_norm,
      gt.domain,
      gt.path_segment_1,
      gt.domain_path1,
      gt.url_depth,
      cl.search_language
    FROM stg_ground_truth_enhanced gt
    LEFT JOIN stg_city_language cl ON gt.city = cl.city
  ),

  auto_enhanced AS (
    SELECT
      a.automation_id,
      a.city,
      a.run_id,
      a.version,
      a.source_url,
      a.source_url_norm,
      a.domain,
      a.path_segment_1,
      a.domain_path1,
      a.url_depth,
      r.is_included
    FROM stg_automation_enhanced a
    LEFT JOIN stg_automation_review r ON a.automation_id = r.automation_id
  ),

  -- Level 1: Exact URL match (100% confidence)
  exact_matches AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.search_language,
      gt.source_url AS gt_url,
      gt.source_url_norm AS gt_url_norm,
      a.automation_id,
      a.run_id,
      a.version,
      a.source_url AS auto_url,
      a.source_url_norm AS auto_url_norm,
      a.is_included,
      'exact_url' AS match_level,
      100 AS confidence_score,
      'AUTO_ACCEPT' AS review_action
    FROM gt_enhanced gt
    INNER JOIN auto_enhanced a
      ON gt.source_url_norm = a.source_url_norm
      AND gt.city = a.city
  ),

  -- Level 2: Domain + Path Segment 1 match (75% confidence)
  -- Distinguishes facebook.com/groups/* from facebook.com/events/*
  domain_path_matches AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.search_language,
      gt.source_url AS gt_url,
      gt.source_url_norm AS gt_url_norm,
      a.automation_id,
      a.run_id,
      a.version,
      a.source_url AS auto_url,
      a.source_url_norm AS auto_url_norm,
      a.is_included,
      'domain_path1' AS match_level,
      75 AS confidence_score,
      'MANUAL_REVIEW' AS review_action
    FROM gt_enhanced gt
    INNER JOIN auto_enhanced a
      ON gt.domain_path1 = a.domain_path1
      AND gt.city = a.city
      AND gt.source_url_norm != a.source_url_norm  -- Exclude exact matches
    WHERE gt.path_segment_1 IS NOT NULL  -- Only if path exists
  ),

  -- Level 3: Domain only match (40% confidence)
  -- Low confidence - needs manual review
  -- Useful for simple domains but risky for platforms like Facebook
  domain_only_matches AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.search_language,
      gt.source_url AS gt_url,
      gt.source_url_norm AS gt_url_norm,
      a.automation_id,
      a.run_id,
      a.version,
      a.source_url AS auto_url,
      a.source_url_norm AS auto_url_norm,
      a.is_included,
      'domain_only' AS match_level,
      CASE
        -- Lower confidence for known platforms
        WHEN gt.domain IN ('facebook.com', 'instagram.com', 'twitter.com', 'linkedin.com')
        THEN 20
        -- Higher confidence for unique domains
        ELSE 40
      END AS confidence_score,
      'MANUAL_REVIEW' AS review_action
    FROM gt_enhanced gt
    INNER JOIN auto_enhanced a
      ON gt.domain = a.domain
      AND gt.city = a.city
      AND (
        gt.domain_path1 != a.domain_path1
        OR gt.path_segment_1 IS NULL
        OR a.path_segment_1 IS NULL
      )
      AND gt.source_url_norm != a.source_url_norm  -- Exclude exact matches
  )

-- Combine all levels
SELECT * FROM exact_matches
UNION ALL
SELECT * FROM domain_path_matches
UNION ALL
SELECT * FROM domain_only_matches
ORDER BY ground_truth_id, confidence_score DESC, automation_id;


-- ============================================================
-- 2) BEST MATCHES: Top match per ground truth URL
-- ============================================================

CREATE OR REPLACE VIEW v_url_best_matches AS
WITH
  all_matches AS (
    SELECT * FROM v_url_matches_all_levels
  ),

  ranked_matches AS (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY ground_truth_id
        ORDER BY confidence_score DESC, automation_id
      ) AS match_rank
    FROM all_matches
  )

SELECT
  ground_truth_id,
  city,
  search_language,
  gt_url,
  automation_id,
  run_id,
  version,
  auto_url,
  is_included,
  match_level,
  confidence_score,
  review_action
FROM ranked_matches
WHERE match_rank = 1
ORDER BY city, ground_truth_id;


-- ============================================================
-- 3) MATCH SUMMARY: Statistics by confidence level
-- ============================================================

CREATE OR REPLACE VIEW v_match_summary_by_level AS
WITH
  gt_total AS (
    SELECT
      city,
      search_language,
      COUNT(*) AS total_ground_truth
    FROM stg_ground_truth_enhanced gt
    LEFT JOIN stg_city_language cl ON gt.city = cl.city
    GROUP BY city, search_language
  ),

  matches_by_level AS (
    SELECT
      city,
      search_language,
      match_level,
      confidence_score,
      COUNT(DISTINCT ground_truth_id) AS matched_count,
      COUNT(*) AS total_matches,
      SUM(CASE WHEN is_included THEN 1 ELSE 0 END) AS valid_matches
    FROM v_url_matches_all_levels
    GROUP BY city, search_language, match_level, confidence_score
  )

SELECT
  m.city,
  m.search_language,
  m.match_level,
  m.confidence_score,
  m.matched_count,
  gt.total_ground_truth,
  ROUND(m.matched_count * 100.0 / NULLIF(gt.total_ground_truth, 0), 2) AS match_rate_percent,
  m.total_matches,
  m.valid_matches,
  ROUND(m.valid_matches * 100.0 / NULLIF(m.total_matches, 0), 2) AS precision_percent
FROM matches_by_level m
JOIN gt_total gt ON m.city = gt.city AND m.search_language = gt.search_language
ORDER BY m.city, m.search_language, m.confidence_score DESC;


-- ============================================================
-- 4) UNMATCHED URLs: Ground truth with no matches at any level
-- ============================================================

CREATE OR REPLACE VIEW v_unmatched_ground_truth AS
WITH
  matched_ids AS (
    SELECT DISTINCT ground_truth_id
    FROM v_url_matches_all_levels
  ),

  gt_with_lang AS (
    SELECT
      gt.ground_truth_id,
      gt.city,
      gt.source_url,
      gt.domain,
      gt.path_segment_1,
      gt.url_depth,
      cl.search_language
    FROM stg_ground_truth_enhanced gt
    LEFT JOIN stg_city_language cl ON gt.city = cl.city
  )

SELECT
  gt.ground_truth_id,
  gt.city,
  gt.search_language,
  gt.source_url,
  gt.domain,
  gt.path_segment_1,
  gt.url_depth
FROM gt_with_lang gt
LEFT JOIN matched_ids m ON gt.ground_truth_id = m.ground_truth_id
WHERE m.ground_truth_id IS NULL
ORDER BY gt.city, gt.ground_truth_id;


-- ============================================================
-- 5) MANUAL REVIEW QUEUE: Matches requiring human review
-- ============================================================

CREATE OR REPLACE VIEW v_manual_review_queue AS
SELECT
  ground_truth_id,
  city,
  search_language,
  gt_url,
  automation_id,
  run_id,
  version,
  auto_url,
  is_included,
  match_level,
  confidence_score,
  review_action,
  CASE
    WHEN match_level = 'domain_path1' THEN 'Medium confidence - Check if same topic/group'
    WHEN match_level = 'domain_only' AND confidence_score <= 20 THEN 'Low confidence - Platform domain (Facebook/Instagram)'
    WHEN match_level = 'domain_only' THEN 'Low confidence - Domain match only'
    ELSE 'Review needed'
  END AS review_note
FROM v_url_matches_all_levels
WHERE review_action = 'MANUAL_REVIEW'
  AND is_included IS NOT NULL  -- Only show automation results that were reviewed
ORDER BY confidence_score DESC, city, ground_truth_id;


-- ============================================================
-- 6) OVERALL RECALL BY CONFIDENCE LEVEL
-- ============================================================

CREATE OR REPLACE VIEW v_recall_by_confidence AS
WITH
  gt_total AS (
    SELECT COUNT(DISTINCT ground_truth_id) AS total_gt
    FROM stg_ground_truth_enhanced
  ),

  matches_by_confidence AS (
    SELECT
      CASE
        WHEN confidence_score = 100 THEN 'High (100%)'
        WHEN confidence_score = 75 THEN 'Medium (75%)'
        WHEN confidence_score >= 40 THEN 'Low (40%)'
        ELSE 'Very Low (20%)'
      END AS confidence_level,
      MIN(confidence_score) AS min_score,
      MAX(confidence_score) AS max_score,
      COUNT(DISTINCT ground_truth_id) AS matched_gt
    FROM v_url_best_matches
    GROUP BY
      CASE
        WHEN confidence_score = 100 THEN 'High (100%)'
        WHEN confidence_score = 75 THEN 'Medium (75%)'
        WHEN confidence_score >= 40 THEN 'Low (40%)'
        ELSE 'Very Low (20%)'
      END
  )

SELECT
  m.confidence_level,
  m.min_score,
  m.max_score,
  m.matched_gt,
  gt.total_gt,
  ROUND(m.matched_gt * 100.0 / NULLIF(gt.total_gt, 0), 2) AS recall_percent
FROM matches_by_confidence m
CROSS JOIN gt_total gt
ORDER BY m.min_score DESC;


-- ============================================================
-- USAGE EXAMPLES:
-- ============================================================

-- View all matches for a specific ground truth URL
-- SELECT * FROM v_url_matches_all_levels WHERE ground_truth_id = 'ground_truth_001';

-- View best match per ground truth
-- SELECT * FROM v_url_best_matches WHERE city = 'cork';

-- View match statistics by level
-- SELECT * FROM v_match_summary_by_level;

-- View manual review queue
-- SELECT * FROM v_manual_review_queue WHERE city = 'galway' LIMIT 20;

-- View unmatched URLs
-- SELECT * FROM v_unmatched_ground_truth;

-- View overall recall by confidence level
-- SELECT * FROM v_recall_by_confidence;
