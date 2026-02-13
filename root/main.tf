
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

  depends_on = [
    azurerm_role_assignment.adls_uc,
    azurerm_role_assignment.ac_reader
  ]
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
# Role Assignment: MI Reader on Self
# Required for Databricks to create Storage Credential
# -----------------------------
resource "azurerm_role_assignment" "ac_reader" {
  scope                = module.access_connector.id
  role_definition_name = "Reader"
  principal_id         = module.access_connector.principal_id
}



# -----------------------------
# Unity Catalog
# -----------------------------
# resource "databricks_catalog" "main" {
#   name    = local.catalog
#   comment = "Main lakehouse catalog for ${terraform.workspace} environment"

#   depends_on = [
#     module.databricks_workspace,
#     module.external_locations
#   ]
# }

# -----------------------------
# Git Repository Integration
# -----------------------------
resource "databricks_repo" "crypto_pipeline" {
  url  = var.pipeline_repo_url
  path = "/Repos/${local.prefix}/crypto-pipeline"

  depends_on = [
    module.databricks_workspace
  ]
}

# -----------------------------
# Schemas (Declarative YAML-Driven)
# -----------------------------
locals {
  schemas_config = yamldecode(file("${path.module}/schemas.yaml"))
}

resource "databricks_schema" "schemas" {
  for_each = { for schema in local.schemas_config.schemas : schema.name => schema }

  catalog_name = local.catalog
  name         = each.value.name
  comment      = lookup(each.value, "comment", null)

  depends_on = [
    # databricks_catalog.main,
    module.databricks_workspace
  ]
}

# -----------------------------
# DLT Pipelines (Declarative YAML-Driven)
# -----------------------------
locals {
  pipelines_config = yamldecode(file("${path.module}/pipelines.yaml"))

  # Replace template variables in pipeline paths.
  pipelines_processed = [
    for pipeline in local.pipelines_config.pipelines : merge(pipeline, {
      storage_path = replace(
        pipeline.storage_path,
        "{storage_account}",
        module.storage.account_name
      )
      notebook_path = try(
        replace(pipeline.notebook_path, "{repo_prefix}", local.prefix),
        null
      )
      file_path = try(
        replace(pipeline.file_path, "{repo_prefix}", local.prefix),
        null
      )
    })
  ]
}

resource "databricks_pipeline" "pipelines" {
  for_each = { for pipeline in local.pipelines_processed : pipeline.name => pipeline }

  name       = each.value.name
  continuous = lookup(each.value, "continuous", false)
  catalog    = local.catalog
  target     = each.value.target_schema
  storage    = each.value.storage_path

  # Support multiple libraries if defined in YAML, fallback to single notebook_path
  dynamic "library" {
    for_each = lookup(each.value, "libraries", [])
    content {
      notebook {
        path = library.value.notebook_path
      }
    }
  }

  dynamic "library" {
    for_each = lookup(each.value, "notebook_path", null) != null ? [1] : []
    content {
      notebook {
        path = each.value.notebook_path
      }
    }
  }

  dynamic "library" {
    for_each = lookup(each.value, "file_path", null) != null ? [1] : []
    content {
      file {
        path = each.value.file_path
      }
    }
  }

  configuration = merge(
    lookup(each.value, "configuration", {}),
    {
      "pipelines.catalog"         = local.catalog
      "pipelines.storage_account" = module.storage.account_name
    }
  )

  depends_on = [
    # databricks_catalog.main,
    module.databricks_workspace,
    module.external_locations,
    databricks_schema.schemas,
    databricks_repo.crypto_pipeline
  ]
}
