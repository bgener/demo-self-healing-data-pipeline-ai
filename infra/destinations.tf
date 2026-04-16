# =============================================================================
# Destination: ClickHouse
# =============================================================================
resource "airbyte_destination_clickhouse" "analytics" {
  name         = "ClickHouse Analytics"
  workspace_id = local.workspace_id

  configuration = {
    host     = var.clickhouse_host
    port     = var.clickhouse_port
    database = "raw"
    username = var.clickhouse_username
    password = var.clickhouse_password
    ssl      = false
  }
}
