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

variable "pg_superuser" {
  description = "TimescaleDB superuser (owns schemas)"
  type        = string
  default     = "postgres"
}

variable "pg_superuser_password" {
  description = "TimescaleDB superuser password"
  type        = string
  sensitive   = true
  default     = "postgres"
}

variable "pg_user" {
  description = "Pipeline role (non-superuser, receives grants)"
  type        = string
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
