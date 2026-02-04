module "resource_group" {
  source   = "../modules/resource_group"
  name     = "${local.prefix}-rg"
  location = local.location
}

module "storage" {
  source     = "../modules/storage"
  name       = replace("${local.prefix}dl", "-", "")
  rg_name    = module.resource_group.name
  location   = local.location
  containers = local.containers
}

module "databricks_workspace" {
  source   = "../modules/databricks_workspace"
  name     = "${local.prefix}-dbw"
  rg_name  = module.resource_group.name
  location = local.location
}

provider "databricks" {
  host = module.databricks_workspace.workspace_url
}

module "unity_catalog" {
  source       = "../modules/unity_catalog"
  name         = "${local.prefix}-metastore"
  workspace_id = module.databricks_workspace.workspace_id
  storage_root = "abfss://gold@${module.storage.account_name}.dfs.core.windows.net/"
}


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

module "jobs" {
  source       = "../modules/jobs"
  environment  = var.environment
  node_type_id = local.cluster_node_type[var.environment]
  is_prod      = local.is_prod
}

module "dlt" {
  source           = "../modules/dlt_pipeline"
  name             = "bronze_pipeline"
  catalog          = "main"   # Existing Unity Catalog metastore catalog
  schema           = "bronze" # Schema inside the catalog
  pipeline_storage = "dbfs:/pipelines/bronze"
  continuous       = true
}


resource "azurerm_role_assignment" "adls_uc" {
  scope                = module.storage.account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.access_connector.principal_id
}

