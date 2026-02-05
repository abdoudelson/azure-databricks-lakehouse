
# -----------------------------
# Resource Group
# -----------------------------
module "resource_group" {
  source   = "../modules/resource_group"
  name     = "${local.prefix}-rg"
  location = local.location
}

# -----------------------------
# Storage Account + Containers
# -----------------------------

module "storage" {
  source     = "../modules/storage"
  name       = replace("${local.prefix}dl", "-", "")
  rg_name    = module.resource_group.name
  location   = local.location
  containers = local.containers
}

# -----------------------------
# Databricks Workspace
# -----------------------------

module "databricks_workspace" {
  source   = "../modules/databricks_workspace"
  name     = "${local.prefix}-dbw"
  rg_name  = module.resource_group.name
  location = local.location
}

provider "databricks" {
  host = module.databricks_workspace.workspace_url
}


# -----------------------------
# Access Connector
# -----------------------------
module "access_connector" {
  source   = "../modules/access_connector"
  name     = "${local.prefix}-ac"
  rg_name  = module.resource_group.name
  location = local.location
}

module "external_locations" {
  source              = "../modules/external_locations"
  storage_account     = module.storage.account_name
  containers          = local.containers
  prefix              = local.prefix
  access_connector_id = module.access_connector.id
}

# -----------------------------
# Role Assignment for Storage
# -----------------------------
resource "azurerm_role_assignment" "adls_uc" {
  scope                = module.storage.account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.access_connector.principal_id
}



# -----------------------------
# Schema
# -----------------------------
resource "databricks_schema" "schema_test" {
  catalog_name = local.catalog
  name         = local.schema_name
}

# -----------------------------
# DLT Pipeline
# -----------------------------
module "dlt_pipeline" {
  source = "../modules/dlt_pipeline"

  name       = local.pipeline_name
  continuous = true

  catalog = local.catalog
  schema  = local.schema_name

  pipeline_storage = "abfss://bronze@lakehouseuatdl.dfs.core.windows.net/dlt"

  depends_on = [
    databricks_schema.schema_test
  ]
}
