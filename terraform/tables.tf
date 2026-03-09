# ──────────────────────────────────────────────
# Bronze / Raw Tables
# ──────────────────────────────────────────────

resource "snowflake_table" "raw_automation" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_AUTOMATION"
  comment  = "Automation-discovered FSI URLs"

  column { name = "AUTOMATION_ID" type = "STRING" }
  column { name = "CITY"          type = "STRING" }
  column { name = "RUN_ID"        type = "STRING" }
  column { name = "SOURCE_URL"    type = "STRING" }
  column { name = "FILE_NAME"     type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "raw_automation_reviewed" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_AUTOMATION_REVIEWED"
  comment  = "Manual review decisions for automation URLs"

  column { name = "AUTOMATION_ID" type = "STRING" }
  column { name = "IS_INCLUDED"   type = "STRING" }
  column { name = "FILE_NAME"     type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}

resource "snowflake_table" "raw_city_language" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_CITY_LANGUAGE"
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

resource "snowflake_table" "raw_ground_truth" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_GROUND_TRUTH"
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

resource "snowflake_table" "bronze_blob_inventory_raw" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "BRONZE_BLOB_INVENTORY_RAW"
  comment  = "Azure Blob file inventory snapshot"

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

resource "snowflake_table" "raw_sharecity200_tracker_run01" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "RAW_SHARECITY200_TRACKER_RUN01"
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

resource "snowflake_table" "silver_fsi_201225" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "SILVER_FSI_201225"
  comment  = "Silver snapshot — pre-deduplication FSI data (2025-12-25)"

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
  column { name = "DATE_CHECKED"             type = "STRING" }
  column { name = "LAT"                      type = "FLOAT" }
  column { name = "LON"                      type = "FLOAT" }
  column { name = "ROUND"                    type = "STRING" }
  column { name = "GROWING"                  type = "INTEGER" }
  column { name = "DISTRIBUTION"             type = "INTEGER" }
  column { name = "COOKING_EATING"           type = "INTEGER" }
  column { name = "GIFTING"                  type = "INTEGER" }
  column { name = "COLLECTING"               type = "INTEGER" }
  column { name = "SELLING"                  type = "INTEGER" }
  column { name = "BARTERING"                type = "INTEGER" }
}

resource "snowflake_table" "gold_fsi_200226" {
  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "GOLD_FSI_200226"
  comment  = "Gold snapshot — deduplicated FSI dataset (2026-02-26)"

  column { name = "COUNTRY"                  type = "STRING" }
  column { name = "CITY"                     type = "STRING" }
  column { name = "NAME"                     type = "STRING" }
  column { name = "URL"                      type = "STRING" }
  column { name = "INSTAGRAM_URL"            type = "STRING" }
  column { name = "TWITTER_URL"              type = "STRING" }
  column { name = "FACEBOOK_URL"             type = "STRING" }
  column { name = "FOOD_SHARING_ACTIVITIES"  type = "STRING" }
  column { name = "HOW_IT_IS_SHARED"         type = "STRING" }
  column { name = "LON"                      type = "FLOAT" }
  column { name = "LAT"                      type = "FLOAT" }
  column { name = "COMMENTS"                 type = "STRING" }
  column {
    name    = "LOADED_AT"
    type    = "TIMESTAMP_NTZ"
    default { expression = "CURRENT_TIMESTAMP()" }
  }
}
