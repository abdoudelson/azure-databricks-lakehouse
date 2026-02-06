locals {
  prefix = "lakehouse-${terraform.workspace}"

  location_map = {
    dev  = "westeurope"
    uat  = "westeurope"
    ppd  = "westeurope" # Pre-Production
    test = "westeurope"
    prod = "northeurope"
    prd  = "northeurope" # Production (alias)
  }

  location = local.location_map[terraform.workspace]

  cluster_node_type = {
    dev  = "Standard_DS3_v2"
    uat  = "Standard_DS3_v2"
    ppd  = "Standard_DS3_v2"
    test = "Standard_DS3_v2"
    prod = "Standard_DS5_v2"
    prd  = "Standard_DS5_v2"
  }

  is_prod = terraform.workspace == "prod"

  containers = ["raw", "bronze", "silver", "gold"]

  catalog     = "lakehouse_${terraform.workspace}_dbw"
  schema_name = "schema_bronze"

  pipeline_name    = "bronze-dlt-pipeline"
  pipeline_storage = "dbfs:/pipelines/bronze"

}
