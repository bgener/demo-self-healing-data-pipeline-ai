# =============================================================================
# Connection: DocumentDB -> ClickHouse (hourly)
# =============================================================================
resource "airbyte_connection" "documentdb_to_clickhouse" {
  name           = "DocumentDB to ClickHouse"
  source_id      = airbyte_source_mongodb_v2.documentdb.source_id
  destination_id = airbyte_destination_clickhouse.analytics.destination_id

  schedule = {
    schedule_type = "basic"
    basic_timing  = "Every 1 hour"
  }

  namespace_definition = "destination"
  status               = "active"
}

# =============================================================================
# Connection: CoinGecko -> ClickHouse (every 15 min)
# =============================================================================
resource "airbyte_connection" "coingecko_to_clickhouse" {
  name           = "CoinGecko to ClickHouse"
  source_id      = airbyte_source_custom.coingecko.source_id
  destination_id = airbyte_destination_clickhouse.analytics.destination_id

  schedule = {
    schedule_type = "basic"
    basic_timing  = "Every 15 minutes"
  }

  namespace_definition = "destination"
  status               = "active"
}
