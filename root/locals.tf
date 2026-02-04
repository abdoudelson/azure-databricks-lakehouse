locals {
  prefix = "lakehouse-${var.environment}"

  location_map = {
    dev  = "westeurope"
    test = "westeurope"
    prod = "northeurope"
  }

  location = local.location_map[var.environment]

  cluster_node_type = {
    dev  = "Standard_DS3_v2"
    test = "Standard_DS3_v2"
    prod = "Standard_DS5_v2"
  }

  is_prod = var.environment == "prod"

  containers = ["raw", "bronze", "silver", "gold"]
}
