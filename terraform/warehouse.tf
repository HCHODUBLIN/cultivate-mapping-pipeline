# ──────────────────────────────────────────────
# Warehouse
# ──────────────────────────────────────────────
resource "snowflake_warehouse" "fsi" {
  name           = var.warehouse_name
  warehouse_size = "X-SMALL"
  auto_suspend   = 60
  auto_resume    = true

  initially_suspended = true
}
