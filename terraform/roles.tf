# ──────────────────────────────────────────────
# Custom Roles (beyond ACCOUNTADMIN)
# ──────────────────────────────────────────────

# Transformer role — used by dbt for running models
resource "snowflake_account_role" "transformer" {
  name    = "CULTIVATE_TRANSFORMER"
  comment = "dbt transformation role — read from raw, write to staging/intermediate/marts"
}

# Reader role — used by dashboards and BI tools
resource "snowflake_account_role" "reader" {
  name    = "CULTIVATE_READER"
  comment = "Read-only access to marts layer for dashboards and analytics"
}

# Loader role — used by ingestion scripts
resource "snowflake_account_role" "loader" {
  name    = "CULTIVATE_LOADER"
  comment = "Data loading role — write to raw schema, read stages"
}

# ──────────────────────────────────────────────
# Role Hierarchy
# ──────────────────────────────────────────────

resource "snowflake_grant_account_role" "transformer_to_admin" {
  role_name        = snowflake_account_role.transformer.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "reader_to_admin" {
  role_name        = snowflake_account_role.reader.name
  parent_role_name = "SYSADMIN"
}

resource "snowflake_grant_account_role" "loader_to_admin" {
  role_name        = snowflake_account_role.loader.name
  parent_role_name = "SYSADMIN"
}

# ──────────────────────────────────────────────
# Warehouse Privileges
# ──────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "transformer_warehouse" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.fsi.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_warehouse" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.fsi.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_warehouse" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.fsi.name
  }
}

# ──────────────────────────────────────────────
# Database Privileges
# ──────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "transformer_database" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cultivate.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_database" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cultivate.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "loader_database" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.cultivate.name
  }
}

# ──────────────────────────────────────────────
# Schema Privileges — Transformer
# ──────────────────────────────────────────────

# raw: read-only (SELECT on tables)
resource "snowflake_grant_privileges_to_account_role" "transformer_raw_read" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_tables" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.raw.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "transformer_raw_future_tables" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.raw.fully_qualified_name
    }
  }
}

# staging: dbt creates and writes models
resource "snowflake_grant_privileges_to_account_role" "transformer_staging" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY"]

  on_schema {
    schema_name = snowflake_schema.staging.fully_qualified_name
  }
}

# intermediate: dbt creates and writes models
resource "snowflake_grant_privileges_to_account_role" "transformer_intermediate" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY"]

  on_schema {
    schema_name = snowflake_schema.intermediate.fully_qualified_name
  }
}

# marts: dbt creates and writes models
resource "snowflake_grant_privileges_to_account_role" "transformer_marts" {
  account_role_name = snowflake_account_role.transformer.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "MODIFY"]

  on_schema {
    schema_name = snowflake_schema.marts.fully_qualified_name
  }
}

# ──────────────────────────────────────────────
# Schema Privileges — Reader (marts only)
# ──────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "reader_marts" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = snowflake_schema.marts.fully_qualified_name
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_marts_tables" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.marts.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_marts_views" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    all {
      object_type_plural = "VIEWS"
      in_schema          = snowflake_schema.marts.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_marts_future_tables" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = snowflake_schema.marts.fully_qualified_name
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "reader_marts_future_views" {
  account_role_name = snowflake_account_role.reader.name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = snowflake_schema.marts.fully_qualified_name
    }
  }
}

# ──────────────────────────────────────────────
# Schema Privileges — Loader (raw only)
# ──────────────────────────────────────────────

resource "snowflake_grant_privileges_to_account_role" "loader_raw" {
  account_role_name = snowflake_account_role.loader.name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "MODIFY"]

  on_schema {
    schema_name = snowflake_schema.raw.fully_qualified_name
  }
}
