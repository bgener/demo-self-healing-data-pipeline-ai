variable "pg_host" {
  description = "TimescaleDB hostname"
  type        = string
  default     = "localhost"
}

variable "pg_port" {
  description = "TimescaleDB port"
  type        = number
  default     = 5432
}

variable "pg_user" {
  description = "TimescaleDB admin user"
  type        = string
  default     = "pipeline"
}

variable "pg_password" {
  description = "TimescaleDB admin password"
  type        = string
  sensitive   = true
  default     = "pipeline"
}

variable "pg_database" {
  description = "TimescaleDB database name"
  type        = string
  default     = "warehouse"
}

variable "pg_schemas" {
  description = "Schemas to create in the warehouse"
  type        = list(string)
  default     = ["raw", "staging", "intermediate", "marts"]
}
