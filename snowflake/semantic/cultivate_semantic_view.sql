-- CULTIVATE Semantic View
-- Purpose: Enables Cortex Analyst natural language querying of food sharing initiative data
-- Tables: GOLD_INITIATIVES
-- Note: Additional survey metric tables to be added when available
-- Last updated: 2026-03-04
-- Run once manually in Snowsight worksheet after any schema change

CREATE OR REPLACE SEMANTIC VIEW CULTIVATE_DB.GOLD.CULTIVATE_SEMANTIC_VIEW
  COMMENT = 'Semantic layer for Cortex Analyst — food sharing initiatives across 105 European cities'
AS
  TABLE CULTIVATE_DB.GOLD.GOLD_INITIATIVES
    PRIMARY KEY (URL)

    -- ── Dimensions ──────────────────────────────────────────────────────

    DIMENSION COUNTRY
      COMMENT = 'Country where the initiative operates'

    DIMENSION CITY
      SYNONYMS = ('urban area', 'municipality', 'location')
      COMMENT = 'City where the initiative is based'

    DIMENSION NAME
      COMMENT = 'Name of the food sharing organisation or initiative'

    DIMENSION FOOD_SHARING_ACTIVITIES
      SYNONYMS = ('activity type', 'category', 'initiative type', 'practice', 'what they do')
      COMMENT = 'Primary type of food sharing activity'

    DIMENSION HOW_IT_IS_SHARED
      SYNONYMS = ('sharing method', 'distribution method', 'model')
      COMMENT = 'Method used to distribute or share food'

    DIMENSION LOADED_AT
      COMMENT = 'Date the record was ingested'

    -- ── Facts ───────────────────────────────────────────────────────────

    FACT LON
      COMMENT = 'Longitude coordinate'

    FACT LAT
      COMMENT = 'Latitude coordinate'

    -- ── Metrics ─────────────────────────────────────────────────────────

    METRIC total_initiatives = COUNT(URL)
      COMMENT = 'Total number of food sharing initiatives'

    METRIC initiatives_with_instagram = COUNT(URL) FILTER (WHERE INSTAGRAM_URL IS NOT NULL)
      COMMENT = 'Number of initiatives with an Instagram presence'

    METRIC initiatives_with_twitter = COUNT(URL) FILTER (WHERE TWITTER_URL IS NOT NULL)
      COMMENT = 'Number of initiatives with a Twitter/X presence'

    METRIC initiatives_with_facebook = COUNT(URL) FILTER (WHERE FACEBOOK_URL IS NOT NULL)
      COMMENT = 'Number of initiatives with a Facebook presence'

    METRIC social_media_coverage =
      COUNT(URL) FILTER (WHERE INSTAGRAM_URL IS NOT NULL
                            OR TWITTER_URL  IS NOT NULL
                            OR FACEBOOK_URL IS NOT NULL)
      * 100.0 / COUNT(URL)
      COMMENT = 'Percentage of initiatives with at least one social media presence'
;

-- ── Grants ────────────────────────────────────────────────────────────

-- Grant SELECT on semantic view to analyst role
GRANT SELECT ON SEMANTIC VIEW CULTIVATE_DB.GOLD.CULTIVATE_SEMANTIC_VIEW TO ROLE ACCOUNTADMIN;

-- Cortex Analyst also requires SELECT on the underlying table
GRANT SELECT ON TABLE CULTIVATE_DB.GOLD.GOLD_INITIATIVES TO ROLE ACCOUNTADMIN;
