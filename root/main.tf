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

module "external_locations" {
  source          = "../modules/external_locations"
  storage_account = module.storage.account_name
  containers      = local.containers
  prefix          = local.prefix
}

module "jobs" {
  source       = "../modules/jobs"
  environment  = var.environment
  node_type_id = local.cluster_node_type[var.environment]
  is_prod      = local.is_prod
}

module "dlt" {
  source           = "../modules/dlt_pipeline"
  name             = "${local.prefix}-transport-dlt"
  target_schema    = "silver"
  pipeline_storage = "abfss://silver@${module.storage.account_name}.dfs.core.windows.net/dlt"
  continuous       = local.is_prod
}
