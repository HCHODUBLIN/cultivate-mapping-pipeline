# ──────────────────────────────────────────────
# Storage Integration — AWS S3
# ──────────────────────────────────────────────

resource "snowflake_storage_integration" "s3" {
  count = var.aws_s3_bucket != "" ? 1 : 0

  name    = "S3_CULTIVATE_INT"
  type    = "EXTERNAL_STAGE"
  enabled = true

  storage_provider          = "S3"
  storage_allowed_locations = ["s3://${var.aws_s3_bucket}/"]
  storage_aws_role_arn      = var.aws_iam_role_arn
}

# ──────────────────────────────────────────────
# External Stage — AWS S3
# ──────────────────────────────────────────────

resource "snowflake_stage" "s3_raw" {
  count = var.aws_s3_bucket != "" ? 1 : 0

  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "STG_S3_RAW"

  url                = "s3://${var.aws_s3_bucket}/cultivate/"
  storage_integration = snowflake_storage_integration.s3[0].name

  file_format = "FORMAT_NAME = ${snowflake_database.cultivate.name}.${snowflake_schema.raw.name}.${snowflake_file_format.csv_default.name}"

  comment = "External stage pointing to AWS S3 for raw data ingestion"
}
