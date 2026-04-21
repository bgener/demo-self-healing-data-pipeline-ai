output "schemas" {
  description = "Managed warehouse schemas"
  value       = [for s in postgresql_schema.pipeline : s.name]
}

output "timescaledb_extension" {
  description = "TimescaleDB extension status"
  value       = postgresql_extension.timescaledb.name
}

output "granted_schemas" {
  description = "Schemas the pipeline role has access to"
  value       = [for g in postgresql_grant.pipeline_schema_usage : g.schema]
}
