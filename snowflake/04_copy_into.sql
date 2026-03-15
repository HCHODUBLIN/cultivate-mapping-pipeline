-- 04_copy_into.sql
-- Load core CULTIVATE datasets from Azure stage with explicit folder paths.
-- Stage root is expected to be:
-- azure://<account>.blob.core.windows.net/cultivate/

COPY INTO bronze_automation (city, country, name, url, facebook_url, twitter_url, instagram_url, food_sharing_activities, how_it_is_shared, date_checked, comments, lat, lon, file_name)
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
         TRY_CAST($12 AS FLOAT), TRY_CAST($13 AS FLOAT), METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/automation.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (B) bronze_automation_reviewed (same structure, invalid rows removed)
COPY INTO bronze_automation_reviewed (city, country, name, url, facebook_url, twitter_url, instagram_url, food_sharing_activities, how_it_is_shared, date_checked, comments, lat, lon, file_name)
FROM (
  SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
         TRY_CAST($12 AS FLOAT), TRY_CAST($13 AS FLOAT), METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/automation_reviewed.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (C) bronze_city_language (legacy 2024)
COPY INTO bronze_city_language (city, search_language, file_name)
FROM (
  SELECT $1, $2, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/city_language.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (D) bronze_ground_truth (legacy 2024)
COPY INTO bronze_ground_truth (ground_truth_id, city, source_url, file_name)
FROM (
  SELECT $1, $2, $3, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/ground_truth.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (E) run-01 tracker load (CSV required)
-- Snowflake COPY INTO cannot ingest .xlsx directly.
-- Convert ShareCity200Tracker.xlsx -> ShareCity200Tracker.csv and upload to:
-- data/bronze/run-01/ShareCity200Tracker.csv
COPY INTO bronze_tracker_run01 (
  region, country, city, language, sharecity_tier, hub_or_spoke, priority,
  dcu_fsi_search_plan_week_commencing, tcd_manual_check_plan_week_commencing,
  data_entry_size_before_manual_checking, manual_review_checker_assigned,
  fsis_searched, data_reviewed, data_uploaded, automation_tool_version,
  comments, valid_fsi, accuracy_rate, correct_name, name_accuracy_rate, file_name
)
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7,
    $8, $9, $10, $11,
    $12, $13, $14, $15,
    $16, $17, $18, $19, $20, METADATA$FILENAME
  FROM @stg_azure_raw
)
PATTERN = '.*data/bronze/run-01/ShareCity200Tracker\\.csv'
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (K) bronze blob inventory snapshot (for dbt stg_bronze_blob_inventory source)
TRUNCATE TABLE bronze_blob_inventory;

LIST @stg_azure_raw PATTERN = '.*data/bronze/.*';
SET BRONZE_LIST_QID = (SELECT LAST_QUERY_ID());

INSERT INTO bronze_blob_inventory (file_path, size_bytes, md5, last_modified)
SELECT
  $1::STRING AS file_path,
  $2::NUMBER AS size_bytes,
  $3::STRING AS md5,
  $4::STRING AS last_modified
FROM TABLE(RESULT_SCAN($BRONZE_LIST_QID))
;
