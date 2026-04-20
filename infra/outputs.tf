output "schemas" {
  description = "Managed warehouse schemas"
  value       = [for s in postgresql_schema.pipeline : s.name]
}

output "timescaledb_extension" {
  description = "TimescaleDB extension status"
  value       = postgresql_extension.timescaledb.name
}
