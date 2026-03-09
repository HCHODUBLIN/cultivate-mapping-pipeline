# ──────────────────────────────────────────────
# Warehouse
# ──────────────────────────────────────────────
resource "snowflake_warehouse" "fsi" {
  name           = var.warehouse_name
  warehouse_size = var.warehouse_size
  auto_suspend   = var.warehouse_auto_suspend
  auto_resume    = true

  initially_suspended = true
}
