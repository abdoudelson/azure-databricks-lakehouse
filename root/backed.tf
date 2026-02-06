terraform {
  backend "azurerm" {
    # These values should be updated to match your infrastructure
    # resource_group_name  = "rg-terraform-state"
    # storage_account_name = "sttfstate"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"
    # use_oidc = true
  }
}
