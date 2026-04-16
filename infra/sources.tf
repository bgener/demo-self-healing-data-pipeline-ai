# =============================================================================
# Source: DocumentDB (via MongoDB connector)
# =============================================================================
resource "airbyte_source_mongodb_v2" "documentdb" {
  name         = "DocumentDB Orders"
  workspace_id = local.workspace_id

  configuration = {
    instance_type = {
      standalone_mongo_db_instance = {
        host     = var.documentdb_host
        port     = var.documentdb_port
        instance = "standalone"
      }
    }
    database    = "ecommerce"
    auth_source = "admin"
    username    = var.documentdb_username
    password    = var.documentdb_password
  }
}

# =============================================================================
# Source: CoinGecko (via Declarative HTTP connector)
# =============================================================================
resource "airbyte_source_custom" "coingecko" {
  name              = "CoinGecko Prices"
  workspace_id      = local.workspace_id
  definition_id     = "dfd88b22-b603-4c3d-aad7-3701784586b1" # HTTP API Source

  configuration = jsonencode({
    url_base = "https://api.coingecko.com/api/v3"
    streams = [
      {
        name               = "coingecko_prices"
        url_path           = "/coins/markets"
        http_method        = "GET"
        request_parameters = {
          vs_currency = "usd"
          ids         = "bitcoin,ethereum"
          order       = "market_cap_desc"
        }
      }
    ]
  })
}
