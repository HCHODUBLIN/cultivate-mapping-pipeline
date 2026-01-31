-- 04_copy_into.sql
-- Load raw tables from Azure stage

-- (A) raw_automation
COPY INTO raw_automation (automation_id, city, run_id, source_url, file_name)
FROM (
  SELECT
    $1, $2, $3, $4,
    METADATA$FILENAME
  FROM @stg_azure_raw
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
PATTERN = '.*automation_raw.*\.csv(\.gz)?$'
ON_ERROR = 'CONTINUE';

-- (B) raw_automation_reviewed
COPY INTO raw_automation_reviewed (automation_id, is_included, file_name)
FROM (
  SELECT
    $1, $2,
    METADATA$FILENAME
  FROM @stg_azure_raw
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
PATTERN = '.*automation_reviewed_raw.*\.csv(\.gz)?$'
ON_ERROR = 'CONTINUE';

-- (C) raw_city_language
COPY INTO raw_city_language (city, search_language, file_name)
FROM (
  SELECT
    $1, $2,
    METADATA$FILENAME
  FROM @stg_azure_raw
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
PATTERN = '.*city_language.*\.csv(\.gz)?$'
ON_ERROR = 'CONTINUE';

-- (D) raw_ground_truth
COPY INTO raw_ground_truth (ground_truth_id, city, source_url, file_name)
FROM (
  SELECT
    $1, $2, $3,
    METADATA$FILENAME
  FROM @stg_azure_raw
)
FILE_FORMAT = (FORMAT_NAME = ff_csv_default)
PATTERN = '.*ground_truth.*\.csv(\.gz)?$'
ON_ERROR = 'CONTINUE';

-- (E) raw_cultivate_api (JSON)
COPY INTO raw_cultivate_api (raw_json, file_name)
FROM (
  SELECT
    $1,
    METADATA$FILENAME
  FROM @stg_azure_raw
)
PATTERN = '.*\.json(\.gz)?$'
ON_ERROR = 'CONTINUE';

-- (F) bronze_sharecity200_raw (CSV) - ShareCity200 pre-deduplication data
COPY INTO bronze_sharecity200_raw (
    country, city, name, url,
    instagram_url, twitter_url, facebook_url,
    food_sharing_activities, how_it_is_shared,
    lon, lat, comments, date_checked, date_modified
)
FROM @stg_azure_raw/bronze/duplication/sharecity200-export-1768225380870.csv
FILE_FORMAT = (FORMAT_NAME = ff_csv_sharecity200)
ON_ERROR = 'CONTINUE';
