# Fetch the default workspace from Airbyte.
# Airbyte OSS creates one workspace automatically on first boot.
data "airbyte_workspace" "default" {}

locals {
  workspace_id = data.airbyte_workspace.default.workspace_id
}
