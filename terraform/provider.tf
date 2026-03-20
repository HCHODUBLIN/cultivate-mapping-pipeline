provider "snowflake" {
  organization_name         = var.snowflake_organization
  account_name              = var.snowflake_account_name
  user                      = var.snowflake_user
  authenticator             = "SNOWFLAKE_JWT"
  private_key               = file(var.snowflake_private_key_path)
  role                      = var.snowflake_role
  preview_features_enabled  = ["snowflake_storage_integration_resource", "snowflake_file_format_resource", "snowflake_stage_resource"]
}

provider "aws" {
  region = var.aws_region
}
