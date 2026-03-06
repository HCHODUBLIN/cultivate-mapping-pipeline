-- 04_copy_into.sql
-- Load core CULTIVATE datasets from Azure stage with explicit folder paths.
-- Stage root is expected to be:
-- azure://<account>.blob.core.windows.net/cultivate/

-- (A) raw_automation (legacy 2024)
COPY INTO raw_automation (automation_id, city, run_id, source_url, file_name)
FROM (
  SELECT $1, $2, $3, $4, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/automation.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (B) raw_automation_reviewed (legacy 2024)
COPY INTO raw_automation_reviewed (automation_id, is_included, file_name)
FROM (
  SELECT $1, $2, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/automation_reviewed.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (C) raw_city_language (legacy 2024)
COPY INTO raw_city_language (city, search_language, file_name)
FROM (
  SELECT $1, $2, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/city_language.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (D) raw_ground_truth (legacy 2024)
COPY INTO raw_ground_truth (ground_truth_id, city, source_url, file_name)
FROM (
  SELECT $1, $2, $3, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('data/exploration_data/legacy_2024_data/ground_truth.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (E) gold snapshot load (current production export 2026-02-17)
COPY INTO gold_fsi_200226 (
  country, city, name, url, instagram_url, twitter_url,
  facebook_url, food_sharing_activities, how_it_is_shared, lon, lat, comments
)
FROM (
  SELECT
    $8, $9, $1, $2, $5, $4,
    $3, $6, $7, $10, $11, $12
  FROM @stg_azure_raw
)
FILES = ('data/gold/prod/2026-02-17/sharecity200-export-1771342197988.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_utf8)
FORCE = TRUE
;

-- (F) silver snapshot load (pre-dedup export, optional)
-- Uncomment if you want to rebuild silver source from 2025-12-05 export.
/*
COPY INTO silver_fsi_201225
FROM @stg_azure_raw
FILES = ('data/gold/prod/2025-12-05/sharecity200-export-1764933656343.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_utf8)
FORCE = TRUE
;
*/

-- (G) run-01 tracker load (CSV required)
-- Snowflake COPY INTO cannot ingest .xlsx directly.
-- Convert ShareCity200Tracker.xlsx -> ShareCity200Tracker.csv and upload to:
-- data/bronze/run-01/ShareCity200Tracker.csv
COPY INTO raw_sharecity200_tracker_run01 (
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

-- (I) raw_bronze_fsi (automation-discovered FSIs, all runs)
-- CSVs at data/bronze/run-XX-csv/ with 13 columns:
-- City, Country, Name, URL, Facebook URL, Twitter URL, Instagram URL,
-- Food Sharing Activities, How it is Shared, Date Checked, Comments, Lat, Lon
COPY INTO raw_bronze_fsi (
  run_id, source_file,
  city, country, name, url,
  facebook_url, twitter_url, instagram_url,
  food_sharing_activities, how_it_is_shared,
  date_checked, comments, lat, lon
)
FROM (
  SELECT
    REGEXP_SUBSTR(METADATA$FILENAME, 'run-[0-9]+'),
    METADATA$FILENAME,
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
    TRY_CAST($12 AS FLOAT),
    TRY_CAST($13 AS FLOAT)
  FROM @stg_azure_raw
)
PATTERN = '.*data/bronze/run-0[0-9]-csv/.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (J) raw_silver_fsi (manually verified FSIs, all runs)
-- CSVs at data/silver/run-XX-csv/ with same 13 columns as bronze.
-- Silver is a subset of bronze (false positives removed by manual review).
COPY INTO raw_silver_fsi (
  run_id, source_file,
  city, country, name, url,
  facebook_url, twitter_url, instagram_url,
  food_sharing_activities, how_it_is_shared,
  date_checked, comments, lat, lon
)
FROM (
  SELECT
    REGEXP_SUBSTR(METADATA$FILENAME, 'run-[0-9]+'),
    METADATA$FILENAME,
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
    TRY_CAST($12 AS FLOAT),
    TRY_CAST($13 AS FLOAT)
  FROM @stg_azure_raw
)
PATTERN = '.*data/silver/run-0[0-9]-csv/.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
FORCE = TRUE
;

-- (K) bronze blob inventory snapshot (for dbt stg_bronze_blob_inventory source)
TRUNCATE TABLE bronze_blob_inventory_raw;

LIST @stg_azure_raw PATTERN = '.*data/bronze/.*';
SET BRONZE_LIST_QID = (SELECT LAST_QUERY_ID());

INSERT INTO bronze_blob_inventory_raw (file_path, size_bytes, md5, last_modified)
SELECT
  $1::STRING AS file_path,
  $2::NUMBER AS size_bytes,
  $3::STRING AS md5,
  $4::STRING AS last_modified
FROM TABLE(RESULT_SCAN($BRONZE_LIST_QID))
;
