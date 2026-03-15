# ──────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────

output "database_name" {
  description = "The Snowflake database name"
  value       = snowflake_database.cultivate.name
}

output "warehouse_name" {
  description = "The Snowflake warehouse name"
  value       = snowflake_warehouse.fsi.name
}

output "schemas" {
  description = "Map of schema names created"
  value = {
    raw          = snowflake_schema.raw.name
    staging      = snowflake_schema.staging.name
    intermediate = snowflake_schema.intermediate.name
    marts        = snowflake_schema.marts.name
  }
}

output "roles" {
  description = "Custom roles created for RBAC"
  value = {
    transformer = snowflake_role.transformer.name
    reader      = snowflake_role.reader.name
    loader      = snowflake_role.loader.name
  }
}

output "table_names" {
  description = "Bronze tables managed by Terraform"
  value = [
    snowflake_table.bronze_automation.name,
    snowflake_table.bronze_automation_reviewed.name,
    snowflake_table.bronze_city_language.name,
    snowflake_table.bronze_ground_truth.name,
    snowflake_table.bronze_blob_inventory.name,
    snowflake_table.bronze_tracker_run01.name,
  ]
}
