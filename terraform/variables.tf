# ──────────────────────────────────────────────
# Snowflake connection
# ──────────────────────────────────────────────
variable "snowflake_organization" {
  description = "Snowflake organization name"
  type        = string
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
}

variable "snowflake_private_key_path" {
  description = "Path to Snowflake RSA private key file"
  type        = string
  default     = "~/.snowflake/snowflake_key.p8"
}

variable "snowflake_role" {
  description = "Snowflake role to use for provisioning"
  type        = string
  default     = "ACCOUNTADMIN"
}

# ──────────────────────────────────────────────
# Project configuration
# ──────────────────────────────────────────────

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
  description = "Schema for raw data loading"
  type        = string
  default     = "HC_LOAD_DATA_FROM_CLOUD"
}

variable "staging_schema_name" {
  description = "Schema for staging cleaned data"
  type        = string
  default     = "STAGING"
}

variable "intermediate_schema_name" {
  description = "Schema for intermediate transformed data"
  type        = string
  default     = "INTERMEDIATE"
}

variable "marts_schema_name" {
  description = "Schema for final business-ready models"
  type        = string
  default     = "MARTS"
}

# ──────────────────────────────────────────────
# AWS S3 stage
# ──────────────────────────────────────────────
variable "aws_s3_bucket" {
  description = "S3 bucket name for external stage"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "eu-north-1"
}

variable "aws_iam_role_arn" {
  description = "IAM Role ARN for Snowflake storage integration"
  type        = string
  default     = ""
}

