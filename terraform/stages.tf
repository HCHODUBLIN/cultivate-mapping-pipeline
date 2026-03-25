# ──────────────────────────────────────────────
# External Stage — Azure Blob Storage
# ──────────────────────────────────────────────

resource "snowflake_stage" "azure_raw" {
  count = var.azure_storage_account != "" ? 1 : 0

  database = snowflake_database.cultivate.name
  schema   = snowflake_schema.raw.name
  name     = "STG_AZURE_RAW"

  url         = "azure://${var.azure_storage_account}.blob.core.windows.net/cultivate/"
  credentials = "AZURE_SAS_TOKEN = '${var.azure_sas_token}'"

  file_format = "FORMAT_NAME = ${snowflake_database.cultivate.name}.${snowflake_schema.raw.name}.${snowflake_file_format.csv_default.name}"

  comment = "External stage pointing to Azure Blob Storage for raw data ingestion"
}
