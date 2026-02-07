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

CREATE TABLE IF NOT EXISTS MART_FSI_POWERBI_EXPORT (
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
country VARCHAR,
city VARCHAR,
name VARCHAR,
url VARCHAR,
instagram_url VARCHAR,
twitter_url VARCHAR,
facebook_url VARCHAR,
food_sharing_activities VARCHAR,
how_it_is_shared VARCHAR,
lon FLOAT,
lat FLOAT,
comments VARCHAR,
date_checked VARCHAR,
date_modified TIMESTAMP,
_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

  