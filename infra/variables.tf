variable "airbyte_url" {
  description = "Airbyte API URL"
  type        = string
  default     = "http://localhost:8000"
}

variable "documentdb_host" {
  description = "DocumentDB hostname (use container name when running in Docker network)"
  type        = string
  default     = "documentdb"
}

variable "documentdb_port" {
  description = "DocumentDB port"
  type        = number
  default     = 10260
}

variable "documentdb_username" {
  description = "DocumentDB admin username"
  type        = string
  default     = "docdbadmin"
}

variable "documentdb_password" {
  description = "DocumentDB admin password"
  type        = string
  sensitive   = true
  default     = "Passw0rd!"
}

variable "clickhouse_host" {
  description = "ClickHouse hostname"
  type        = string
  default     = "clickhouse"
}

variable "clickhouse_port" {
  description = "ClickHouse HTTP port"
  type        = number
  default     = 8123
}

variable "clickhouse_username" {
  description = "ClickHouse username"
  type        = string
  default     = "default"
}

variable "clickhouse_password" {
  description = "ClickHouse password"
  type        = string
  sensitive   = true
  default     = "clickhouse"
}
