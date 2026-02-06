terraform {
  backend "azurerm" {
    # Partial Configuration
    # Local: terraform init -backend-config=backend.conf
    # CI/CD: Handled via GitHub Secrets + Arguments
  }
}
