terraform {
  required_version = ">= 1.0"

  required_providers {
    airbyte = {
      source  = "airbytehq/airbyte"
      version = "~> 0.6"
    }
  }
}
