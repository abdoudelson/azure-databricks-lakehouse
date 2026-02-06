# Azure Databricks Lakehouse - Technical Documentation

This project provisions a **Data Lakehouse** on Azure Databricks using **Terraform** and **GitHub Actions** for CI/CD. It follows the **Medallion Architecture** (Raw, Bronze, Silver, Gold).

---

## 🚀 1. Prerequisites

Before you begin, ensure you have the following:

### Tools

- **Terraform** (v1.5+): [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **Azure CLI**: [Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Access & Permissions

- **Azure Subscription**: You must have `Owner` or `User Access Administrator` permissions on the subscription (or target Resource Group) to:
  - Create Service Principals.
  - Assign Roles (specifically `Storage Blob Data Contributor` to Managed Identities).
- **GitHub Repository Admin**: To configure Secrets and Environments.

### 🔑 Authentication Setup (OIDC)

This project uses **OIDC (OpenID Connect)** for passwordless authentication between GitHub Actions and Azure.

> **See [OIDC_SETUP.md](./OIDC_SETUP.md) for the step-by-step setup guide.**

You must configure these **GitHub Secrets**:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

---

## 🏗️ 2. Architecture & Modules

The infrastructure is modularized in the `modules/` directory.

### Core Modules (Used in Deployment)

| Module                     | Description                                                                                                                |
| :------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **`resource_group`**       | Creates the Azure Resource Group (e.g., `lakehouse-dev-rg`).                                                               |
| **`storage`**              | Provisions ADLS Gen2 Account (`lakehouse<env>dl`) with HNS enabled and containers: `raw`, `bronze`, `silver`, `gold`.      |
| **`databricks_workspace`** | Deploys Azure Databricks Workspace (Premium SKU) with VNet injection (optional) and NPIP.                                  |
| **`access_connector`**     | Creates an Azure **Access Connector for Databricks** (Managed Identity) to allow Unity Catalog to access storage securely. |
| **`external_locations`**   | **Unity Catalog Core**: Creates the Storage Credential and defines **External Locations** for each storage container.      |
| **`dlt_pipeline`**         | Defines a **Delta Live Tables** (DLT) pipeline resource, pointing to the source code repository.                           |

### Available Modules (Future Use)

| Module              | Description                                                                                                                       |
| :------------------ | :-------------------------------------------------------------------------------------------------------------------------------- |
| **`jobs`**          | Templates for Databricks Jobs (e.g., `bronze-autoloader`). Currently available for instantiation but not wired in `root/main.tf`. |
| **`unity_catalog`** | Manages Metastore creation and workspace assignment. _Note: Current deployment uses default per-workspace catalog setup._         |

---

## 🔄 3. CI/CD Pipeline

The project uses **GitHub Actions** for automated deployment. The workflow is defined in `.github/workflows/deploy.yml`.

### Workflow Strategy

| Branch    | Environment        | Terraform Workspace | Usage                         |
| :-------- | :----------------- | :------------------ | :---------------------------- |
| `main`    | **Production**     | `prd`               | Stable release.               |
| `develop` | **Pre-Production** | `ppd`               | Integrated testing.           |
| _Other_   | _Development_      | `dev`               | Feature branches (Plan only). |

### Pipeline Steps

1.  **Authentication**: Logs in to Azure using OIDC (Federated Credentials).
2.  **Checkout**: Pulls the code.
3.  **Validation (Pull Request)**:
    - Runs `terraform fmt -check` to ensure code style.
    - Runs `terraform init` to validate configuration.
4.  **Deployment (Push to main/develop)**:
    - **Determine Workspace**: Dynamic logic to pick `prd` vs `ppd` based on branch.
    - **Init with Dynamic Key**: Initializes backend using the workspace name as the state folder (e.g., `prd/terraform.tfstate`).
    - **Plan**: Generates the execution plan.
    - **Apply**: Automatically applies changes (Auto-approve).

---

## 🛠️ 4. Local Deployment Guide

If you need to run Terraform locally (e.g., for development):

### 1. Setup Backend

Update `root/backed.tf` to point to your Azure Storage Account for state (created during OIDC setup):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate..." # YOUR ACCOUNT
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true # Use false if using AZ CLI login locally without SP
  }
}
```

### 2. Initialize

```bash
cd root
terraform init
```

### 3. Select Workspace

Isolate your environment state:

```bash
terraform workspace new dev
# OR
terraform workspace select dev
```

### 4. Plan & Apply

```bash
terraform plan -out=dev.plan
terraform apply dev.plan
```

---

## 📂 5. Repository Structure

```text
.
├── .github/workflows/   # CI/CD Definitions
├── root/                # 🟢 ENTRY POINT (main.tf, variables.tf)
├── modules/             # 🧩 Reusable Terraform Modules
├── env/                 # 🌍 Environment-specific .tfvars (Optional)
├── OIDC_SETUP.md        # 🔑 Authentication Setup Guide
└── README.md            # 📄 This Documentation
```
