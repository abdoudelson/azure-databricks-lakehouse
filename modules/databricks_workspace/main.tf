resource "azurerm_databricks_workspace" "this" {
  name                = var.name
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = "premium"
}
