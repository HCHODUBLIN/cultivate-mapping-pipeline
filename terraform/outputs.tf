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
    raw = snowflake_schema.raw.name
  }
}

output "roles" {
  description = "Custom roles created for RBAC"
  value = {
    transformer = snowflake_account_role.transformer.name
    reader      = snowflake_account_role.reader.name
    loader      = snowflake_account_role.loader.name
  }
}

