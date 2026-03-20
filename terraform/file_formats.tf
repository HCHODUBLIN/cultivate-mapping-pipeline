# ──────────────────────────────────────────────
# File Formats
# ──────────────────────────────────────────────

resource "snowflake_file_format" "json_strip_array" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "FF_JSON_STRIP_ARRAY"

  format_type        = "JSON"
  strip_outer_array  = true
}

resource "snowflake_file_format" "csv_default" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "FF_CSV_DEFAULT"

  format_type                   = "CSV"
  field_delimiter               = ","
  skip_header                   = 1
  field_optionally_enclosed_by  = "\""
  null_if                       = ["", "NULL"]
}