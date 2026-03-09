# ──────────────────────────────────────────────
# Snowflake connection
# ──────────────────────────────────────────────
variable "snowflake_account" {
  description = "Snowflake account identifier (e.g. YWQBLJD-ON96190)"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
}

variable "snowflake_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

variable "snowflake_role" {
  description = "Snowflake role to use for provisioning"
  type        = string
  default     = "ACCOUNTADMIN"
}

# ──────────────────────────────────────────────
# Project configuration
# ──────────────────────────────────────────────
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "database_name" {
  description = "Name of the Snowflake database"
  type        = string
  default     = "CULTIVATE"
}

variable "warehouse_name" {
  description = "Name of the Snowflake warehouse"
  type        = string
  default     = "FSI_WH"
}

variable "raw_schema_name" {
  description = "Schema for raw/bronze data loading"
  type        = string
  default     = "HC_LOAD_DATA_FROM_CLOUD"
}

variable "warehouse_size" {
  description = "Warehouse size"
  type        = string
  default     = "X-SMALL"
}

variable "warehouse_auto_suspend" {
  description = "Seconds of inactivity before warehouse suspends"
  type        = number
  default     = 60
}

# ──────────────────────────────────────────────
# Azure stage (optional)
# ──────────────────────────────────────────────
variable "azure_storage_account" {
  description = "Azure storage account name for external stage"
  type        = string
  default     = ""
}

variable "azure_sas_token" {
  description = "Azure SAS token for external stage"
  type        = string
  sensitive   = true
  default     = ""
}
