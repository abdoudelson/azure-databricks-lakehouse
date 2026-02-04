resource "databricks_storage_credential" "managed" {
  name = "${var.prefix}-cred"

  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }
}

resource "databricks_external_location" "locations" {
  for_each = toset(var.containers)

  name            = "${each.value}-location"
  url             = "abfss://${each.value}@${var.storage_account}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.managed.name
}
