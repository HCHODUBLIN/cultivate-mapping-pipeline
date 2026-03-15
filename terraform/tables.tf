# ──────────────────────────────────────────────
# Bronze Tables (CSV-ingested source data)
# ──────────────────────────────────────────────

resource "snowflake_table" "bronze_automation" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_AUTOMATION"
  comment  = "Automation-discovered FSI records (all results before review)"

  column { name = "CITY"                     type = "STRING" }
  column { name = "COUNTRY"                  type = "STRING" }
  column { name = "NAME"                     type = "STRING" }
  column { name = "URL"                      type = "STRING" }
  column { name = "FACEBOOK_URL"             type = "STRING" }
  column { name = "TWITTER_URL"              type = "STRING" }
  column { name = "INSTAGRAM_URL"            type = "STRING" }
  column { name = "FOOD_SHARING_ACTIVITIES"  type = "STRING" }
  column { name = "HOW_IT_IS_SHARED"         type = "STRING" }
  column { name = "DATE_CHECKED"             type = "STRING" }
  column { name = "COMMENTS"                 type = "STRING" }
  column { name = "LAT"                      type = "FLOAT" }
  column { name = "LON"                      type = "FLOAT" }
  column { name = "FILE_NAME"                type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_automation_reviewed" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_AUTOMATION_REVIEWED"
  comment  = "Automation FSI records after manual review (invalid rows removed)"

  column { name = "CITY"                     type = "STRING" }
  column { name = "COUNTRY"                  type = "STRING" }
  column { name = "NAME"                     type = "STRING" }
  column { name = "URL"                      type = "STRING" }
  column { name = "FACEBOOK_URL"             type = "STRING" }
  column { name = "TWITTER_URL"              type = "STRING" }
  column { name = "INSTAGRAM_URL"            type = "STRING" }
  column { name = "FOOD_SHARING_ACTIVITIES"  type = "STRING" }
  column { name = "HOW_IT_IS_SHARED"         type = "STRING" }
  column { name = "DATE_CHECKED"             type = "STRING" }
  column { name = "COMMENTS"                 type = "STRING" }
  column { name = "LAT"                      type = "FLOAT" }
  column { name = "LON"                      type = "FLOAT" }
  column { name = "FILE_NAME"                type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_city_language" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_CITY_LANGUAGE"
  comment  = "Language mapping per city for search automation"

  column { name = "CITY"             type = "STRING" }
  column { name = "SEARCH_LANGUAGE"  type = "STRING" }
  column { name = "FILE_NAME"        type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_ground_truth" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_GROUND_TRUTH"
  comment  = "Manually curated ground truth FSI URLs"

  column { name = "GROUND_TRUTH_ID" type = "STRING" }
  column { name = "CITY"            type = "STRING" }
  column { name = "SOURCE_URL"      type = "STRING" }
  column { name = "FILE_NAME"       type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_fsi_verified" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_FSI_VERIFIED"
  comment  = "Verified FSI dataset with enriched fields (renamed from GOLD_FSI_200226)"

  column { name = "ID"                       type = "STRING" }
  column { name = "CITY"                     type = "STRING" }
  column { name = "COUNTRY"                  type = "STRING" }
  column { name = "NAME"                     type = "STRING" }
  column { name = "URL"                      type = "STRING" }
  column { name = "FACEBOOK_URL"             type = "STRING" }
  column { name = "TWITTER_URL"              type = "STRING" }
  column { name = "INSTAGRAM_URL"            type = "STRING" }
  column { name = "FOOD_SHARING_ACTIVITIES"  type = "STRING" }
  column { name = "HOW_IT_IS_SHARED"         type = "STRING" }
  column { name = "LAT"                      type = "FLOAT" }
  column { name = "LON"                      type = "FLOAT" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_blob_inventory" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_BLOB_INVENTORY"
  comment  = "Azure Blob file inventory"

  column { name = "FILE_PATH"      type = "STRING" }
  column { name = "SIZE_BYTES"     type = "NUMBER" }
  column { name = "MD5"            type = "STRING" }
  column { name = "LAST_MODIFIED"  type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "bronze_tracker_run01" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_TRACKER_RUN01"
  comment  = "ShareCity200 tracker metadata for run-01 planning and QA"

  column { name = "REGION"                                    type = "STRING" }
  column { name = "COUNTRY"                                   type = "STRING" }
  column { name = "CITY"                                      type = "STRING" }
  column { name = "LANGUAGE"                                  type = "STRING" }
  column { name = "SHARECITY_TIER"                            type = "STRING" }
  column { name = "HUB_OR_SPOKE"                              type = "STRING" }
  column { name = "PRIORITY"                                  type = "STRING" }
  column { name = "DCU_FSI_SEARCH_PLAN_WEEK_COMMENCING"       type = "STRING" }
  column { name = "TCD_MANUAL_CHECK_PLAN_WEEK_COMMENCING"     type = "STRING" }
  column { name = "DATA_ENTRY_SIZE_BEFORE_MANUAL_CHECKING"    type = "STRING" }
  column { name = "MANUAL_REVIEW_CHECKER_ASSIGNED"            type = "STRING" }
  column { name = "FSIS_SEARCHED"                             type = "STRING" }
  column { name = "DATA_REVIEWED"                             type = "STRING" }
  column { name = "DATA_UPLOADED"                             type = "STRING" }
  column { name = "AUTOMATION_TOOL_VERSION"                   type = "STRING" }
  column { name = "COMMENTS"                                  type = "STRING" }
  column { name = "VALID_FSI"                                 type = "STRING" }
  column { name = "ACCURACY_RATE"                             type = "STRING" }
  column { name = "CORRECT_NAME"                              type = "STRING" }
  column { name = "NAME_ACCURACY_RATE"                        type = "STRING" }
  column { name = "FILE_NAME"                                 type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}
