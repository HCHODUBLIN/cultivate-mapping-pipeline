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

CREATE TABLE IF NOT EXISTS raw_cultivate_api (
  raw_json VARIANT,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS raw_manual_verification (
  city STRING,
  url STRING,
  name STRING,
  is_valid STRING,
  fp_category STRING,
  comments STRING,
  activities STRING,
  how_shared STRING,
  round_version STRING,
  verified_date STRING,
  lat FLOAT,
  lon FLOAT,
  file_name STRING,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS gold_fsi_final (
  id STRING,
  name STRING,
  url STRING,
  facebook_url STRING,
  x_url STRING,
  instagram_url STRING,
  food_sharing_activities STRING,
  how_it_is_shared STRING,
  country STRING,
  city STRING,
  lng FLOAT,
  lat FLOAT
);

CREATE TABLE IF NOT EXISTS mart_fsi_powerbi_export (
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

CREATE TABLE IF NOT EXISTS bronze_sharecity200_raw (
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
  date_checked STRING,
  date_modified TIMESTAMP_NTZ,
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
