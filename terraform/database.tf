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

# Raw / Bronze data loading schema
resource "snowflake_schema" "raw" {
  database = snowflake_database.cultivate.name
  name     = var.raw_schema_name
  comment  = "Bronze layer — raw data loaded from Azure Blob and manual sources"
}

# dbt staging layer (views)
resource "snowflake_schema" "staging" {
  database = snowflake_database.cultivate.name
  name     = "STAGING"
  comment  = "dbt staging layer — cleaned and typed source views"
}

# dbt intermediate layer (views)
resource "snowflake_schema" "intermediate" {
  database = snowflake_database.cultivate.name
  name     = "INTERMEDIATE"
  comment  = "dbt intermediate layer — business logic transformations"
}

# dbt marts / gold layer (tables)
resource "snowflake_schema" "marts" {
  database = snowflake_database.cultivate.name
  name     = "MARTS"
  comment  = "dbt marts layer — production-ready tables for BI and analytics"
}
