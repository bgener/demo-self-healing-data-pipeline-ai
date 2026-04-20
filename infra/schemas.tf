resource "postgresql_extension" "timescaledb" {
  name     = "timescaledb"
  database = var.pg_database
}

resource "postgresql_schema" "pipeline" {
  for_each = toset(var.pg_schemas)
  name     = each.value
  owner    = var.pg_user
}
