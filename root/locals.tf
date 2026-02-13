locals {
  prefix = "azure-dbks-lakehouse-${terraform.workspace}"

  location_map = {
    dev  = "westeurope"
    uat  = "westeurope"
    ppd  = "westeurope" # Pre-Production
    test = "westeurope"
    prd  = "northeurope" # Production (alias)
  }

  location = local.location_map[terraform.workspace]

  cluster_node_type = {
    dev  = "Standard_DS3_v2"
    uat  = "Standard_DS3_v2"
    ppd  = "Standard_DS3_v2"
    test = "Standard_DS3_v2"
    prd  = "Standard_DS5_v2"
  }

  is_prod = terraform.workspace == "prd"

  containers = ["raw", "bronze", "silver", "gold"]

  catalog = var.catalog_name
}
