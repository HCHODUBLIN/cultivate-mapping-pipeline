-- 01_file_formats.sql
-- File formats for JSON and CSV ingestion

CREATE OR REPLACE FILE FORMAT ff_json_strip_array
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;

CREATE OR REPLACE FILE FORMAT ff_csv_default
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL');
