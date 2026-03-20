# ──────────────────────────────────────────────
# Database
# ──────────────────────────────────────────────
resource "snowflake_database" "cultivate" {
  name    = var.database_name
  comment = "CULTIVATE food-sharing initiative mapping project"
}

# ──────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────

resource "snowflake_schema" "raw" {
  database = snowflake_database.cultivate.name
  name     = var.raw_schema_name
  comment = "Source data loaded from AWS S3 and manual sources — no transformation"
}

resource "snowflake_schema" "staging" {
  database = snowflake_database.cultivate.name
  name     = var.staging_schema_name
  comment = "1:1 cleaned source models — cast, rename, dedup (stg_)"
}

resource "snowflake_schema" "intermediate" {
  database = snowflake_database.cultivate.name
  name     = var.intermediate_schema_name
  comment = "Joined and enriched models — business logic applied (int_)"
} 

resource "snowflake_schema" "marts" {
  database = snowflake_database.cultivate.name
  name     = var.marts_schema_name
  comment = "Business-ready entities for BI and analytics (fct_, dim_)"
}