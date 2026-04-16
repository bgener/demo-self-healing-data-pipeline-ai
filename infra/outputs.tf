output "documentdb_connection_id" {
  description = "Airbyte connection ID for DocumentDB sync (set as AIRBYTE_ORDERS_CONNECTION_ID)"
  value       = airbyte_connection.documentdb_to_clickhouse.connection_id
}

output "coingecko_connection_id" {
  description = "Airbyte connection ID for CoinGecko sync (set as AIRBYTE_COINGECKO_CONNECTION_ID)"
  value       = airbyte_connection.coingecko_to_clickhouse.connection_id
}
