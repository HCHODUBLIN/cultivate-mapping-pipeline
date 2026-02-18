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

-- (F) gold_fsi_final (optional)
-- Enable when gold_fsi_final.csv exists in stage root.
/*
COPY INTO gold_fsi_final (
  id, name, url, facebook_url, x_url, instagram_url,
  food_sharing_activities, how_it_is_shared,
  country, city, lng, lat
)
FROM @stg_azure_raw
FILES = ('gold_fsi_final.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
*/

-- (G) mart_fsi_powerbi_export (optional)
-- Enable when mart_fsi_powerbi_export.csv exists in stage root.
/*
COPY INTO mart_fsi_powerbi_export
FROM @stg_azure_raw
FILES = ('mart_fsi_powerbi_export.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
*/

-- (H) bronze_sharecity200_raw (optional)
-- Use FILES with the exact filename uploaded to stage.
/*
COPY INTO bronze_sharecity200_raw
FROM @stg_azure_raw
FILES = ('<sharecity200-export-file>.csv')
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
;
*/
