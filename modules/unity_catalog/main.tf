resource "databricks_metastore" "this" {
  name         = var.name
  storage_root = var.storage_root
}

resource "databricks_metastore_assignment" "this" {
  workspace_id = var.workspace_id
  metastore_id = databricks_metastore.this.id
}
