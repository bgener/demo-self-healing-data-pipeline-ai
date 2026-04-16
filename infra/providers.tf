provider "airbyte" {
  # Points to local Airbyte OSS instance started by docker compose
  server_url = var.airbyte_url
}
