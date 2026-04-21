resource "postgresql_extension" "timescaledb" {
  name     = "timescaledb"
  database = var.pg_database
}

resource "postgresql_schema" "pipeline" {
  for_each = toset(var.pg_schemas)
  name     = each.value
  owner    = var.pg_superuser
}

# Grant the pipeline role access to each schema.
# Without these grants, dbt and ingestion scripts cannot read or write data.
resource "postgresql_grant" "pipeline_schema_usage" {
  for_each    = toset(var.pg_schemas)
  database    = var.pg_database
  role        = var.pg_user
  schema      = each.value
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]

  depends_on = [postgresql_schema.pipeline]
}

# Grant the pipeline role access to all existing tables in each schema.
resource "postgresql_grant" "pipeline_table_access" {
  for_each    = toset(var.pg_schemas)
  database    = var.pg_database
  role        = var.pg_user
  schema      = each.value
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [postgresql_schema.pipeline]
}

# Default privileges so the pipeline role can access tables created later.
resource "postgresql_default_privileges" "pipeline_tables" {
  for_each    = toset(var.pg_schemas)
  database    = var.pg_database
  role        = var.pg_user
  owner       = var.pg_superuser
  schema      = each.value
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE"]

  depends_on = [postgresql_schema.pipeline]
}
