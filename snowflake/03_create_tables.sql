-- 03_create_tables.sql

CREATE TABLE IF NOT EXISTS raw_automation (
  automation_id STRING,
  city STRING,
  run_id STRING,
  source_url STRING,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_automation_reviewed (
  automation_id STRING,
  is_included STRING,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_city_language (
  city STRING,
  search_language STRING,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_ground_truth (
  ground_truth_id STRING,
  city STRING,
  source_url STRING,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS bronze_blob_inventory_raw (
  file_path STRING,
  size_bytes NUMBER,
  md5 STRING,
  last_modified STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_sharecity200_tracker_run01 (
  region STRING,
  country STRING,
  city STRING,
  language STRING,
  sharecity_tier STRING,
  hub_or_spoke STRING,
  priority STRING,
  dcu_fsi_search_plan_week_commencing STRING,
  tcd_manual_check_plan_week_commencing STRING,
  data_entry_size_before_manual_checking STRING,
  manual_review_checker_assigned STRING,
  fsis_searched STRING,
  data_reviewed STRING,
  data_uploaded STRING,
  automation_tool_version STRING,
  comments STRING,
  valid_fsi STRING,
  accuracy_rate STRING,
  correct_name STRING,
  name_accuracy_rate STRING,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_bronze_fsi (
  city STRING,
  country STRING,
  name STRING,
  url STRING,
  facebook_url STRING,
  twitter_url STRING,
  instagram_url STRING,
  food_sharing_activities STRING,
  how_it_is_shared STRING,
  date_checked STRING,
  comments STRING,
  lat FLOAT,
  lon FLOAT,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_silver_fsi (
  city STRING,
  country STRING,
  name STRING,
  url STRING,
  facebook_url STRING,
  twitter_url STRING,
  instagram_url STRING,
  food_sharing_activities STRING,
  how_it_is_shared STRING,
  date_checked STRING,
  comments STRING,
  lat FLOAT,
  lon FLOAT,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS silver_fsi_201225 (
  id STRING,
  city STRING,
  country STRING,
  name STRING,
  url STRING,
  facebook_url STRING,
  twitter_url STRING,
  instagram_url STRING,
  food_sharing_activities STRING,
  how_it_is_shared STRING,
  date_checked STRING,
  lat FLOAT,
  lon FLOAT,
  round STRING,
  growing INTEGER,
  distribution INTEGER,
  cooking_eating INTEGER,
  gifting INTEGER,
  collecting INTEGER,
  selling INTEGER,
  bartering INTEGER
);

CREATE TABLE IF NOT EXISTS gold_fsi_200226 (
  country STRING,
  city STRING,
  name STRING,
  url STRING,
  instagram_url STRING,
  twitter_url STRING,
  facebook_url STRING,
  food_sharing_activities STRING,
  how_it_is_shared STRING,
  lon FLOAT,
  lat FLOAT,
  comments STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
