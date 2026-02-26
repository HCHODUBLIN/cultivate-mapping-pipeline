-- 04_copy_into.sql
-- Load raw tables from Azure stage
-- Stage root is expected to be:
-- azure://<account>.blob.core.windows.net/cultivate/

-- (A) raw_automation (automation.csv)
COPY INTO raw_automation (automation_id, city, run_id, source_url, file_name)
FROM (
  SELECT $1, $2, $3, $4, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('automation.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;

-- (B) raw_automation_reviewed (automation_reviewed.csv)
COPY INTO raw_automation_reviewed (automation_id, is_included, file_name)
FROM (
  SELECT $1, $2, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('automation_reviewed.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;

-- (C) raw_city_language (city_language.csv)
COPY INTO raw_city_language (city, search_language, file_name)
FROM (
  SELECT $1, $2, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('city_language.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;

-- (D) raw_ground_truth (ground_truth.csv)
COPY INTO raw_ground_truth (ground_truth_id, city, source_url, file_name)
FROM (
  SELECT $1, $2, $3, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('ground_truth.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;

-- (E) raw_cultivate_api (optional)
-- Enable when file exists in stage root:
--   CopyCultivateAPItoBlob or cultivate_api_YYYYMMDD.json
/*
COPY INTO raw_cultivate_api (raw_json, file_name)
FROM (
  SELECT $1, METADATA$FILENAME
  FROM @stg_azure_raw
)
FILES = ('CopyCultivateAPItoBlob')
FILE_FORMAT = (FORMAT_NAME = ff_json_strip_array)
;
*/

-- (F) gold_fsi_200226 (optional)
-- Enable when gold_fsi_200226.csv exists in stage root.
/*
COPY INTO gold_fsi_200226 (
  country, city, name, url, instagram_url, twitter_url,
  facebook_url, food_sharing_activities, how_it_is_shared, lon, lat, comments
)
FROM @stg_azure_raw
FILES = ('gold_fsi_200226.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
*/

-- (G) silver_fsi_201225 (optional)
-- Enable when silver_fsi_201225.csv exists in stage root.
/*
COPY INTO silver_fsi_201225
FROM @stg_azure_raw
FILES = ('silver_fsi_201225.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
*/

-- (H) gold_fsi_200226 (optional)
-- Uses the latest uploaded ShareCity200 export as of 2026-02-17.
-- Source file has 12 columns; map explicitly to avoid column-count mismatch.
COPY INTO gold_fsi_200226 (
  country, city, name, url, instagram_url, twitter_url,
  facebook_url, food_sharing_activities, how_it_is_shared, lon, lat, comments
)
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6,
    $7, $8, $9, $10, $11, $12
  FROM @stg_azure_raw
)
FILES = ('sharecity200-export-1771342197988.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
