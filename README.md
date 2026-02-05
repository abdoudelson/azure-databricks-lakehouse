# Azure Databricks Lakehouse - Technical Documentation

## 1. Codebase Overview
This project uses **Terraform** to deploy an **Azure Databricks Lakehouse** infrastructure. It is designed to be multi-environment (Dev, UAT, Prod) using **Terraform Workspaces**.

### Core Technologies
*   **Infrastructure as Code**: Terraform (AzureRM + Databricks providers).
*   **Governance**: Databricks Unity Catalog (Metastore, External Locations).
*   **Data Layout**: Medallion Architecture (Raw, Bronze, Silver, Gold).
*   **ETL**: Delta Live Tables (DLT).

## 2. Folder Structure

```text
.
├── root/                       # 🟢 ENTRY POINT
│   ├── main.tf                 # Orchestrates the modules.
│   ├── locals.tf               # Environment variables (maps workspace name to Azure region, SKU, etc).
│   ├── providers.tf            # Azure & Databricks provider setup.
│   ├── variables.tf            # Global variables (e.g., subscription_id).
│   └── backed.tf               # Terraform backend config (State storage). *Currently empty*.
│
├── modules/                    # 🧩 REUSABLE COMPONENTS
│   ├── resource_group/         # Creates the Azure Resource Group.
│   ├── storage/                # Creates ADLS Gen2 Account + Containers (Raw/Bronze/Silver/Gold).
│   ├── databricks_workspace/   # Creates Azure Databricks Workspace (Premium SKU).
│   ├── access_connector/       # Creates the Azure Managed Identity for Databricks Access.
│   ├── external_locations/     # Unity Catalog setup (Storage Credential + External Locations).
│   └── dlt_pipeline/           # Defines the Delta Live Tables pipeline resource.
│
├── env/                        # 🌍 ENVIRONMENT SPECIFICS
│   ├── dev.tfvars              # Variables for Development.
│   ├── uat.tfvars              # Variables for UAT.
│   └── prod.tfvars             # Variables for Production.
```

## 3. Module Explanations

### `root/main.tf`
This is the "brain" of the deployment.
*   **Resource Group**: One per environment (e.g., `lakehouse-dev-rg`).
*   **Storage**: Creates `lakehouse<env>dl` (Data Lake) with HNS enabled.
*   **Networking/Security**: Grants `Storage Blob Data Contributor` to the Databricks Access Connector Managed Identity.
*   **Connects Components**: Passes the Storage outputs to the Databricks Workspace and Unity Catalog modules.

### `root/locals.tf`
This file makes the code "smart" about environments. It uses the `terraform.workspace` name to decide:
*   **Region**: `westeurope` for Dev/UAT, `northeurope` for Prod.
*   **Cluster Size**: Larger nodes (`Standard_DS5_v2`) for Prod, smaller for Dev.

### `modules/external_locations`
Critically important for **Unity Catalog**.
1.  Creates a **Storage Credential** that uses the Azure Managed Identity (Access Connector).
2.  Loops through your containers (`raw`, `bronze`, etc.) and creates an **External Location** for each. This allows you to write SQL like `CREATE TABLE catalog.schema.table LOCATION 'abfss://...'` securely.

### `modules/dlt_pipeline`
Deploys a Delta Live Tables pipeline.
*   **Source Code**: It points to a Git repo folder `/Repos/dlt/transport_pipeline`. **Note**: You must ensure this repo is checked out in your workspace or the path is correct.

## 4. Deployment Guide

### ✅ Prerequisites
1.  **Terraform installed** (v1.5+).
2.  **Azure CLI installed** and authenticated (`az login`).
3.  **Owner/Contributor access** on the target Azure Subscription (to create Resource Groups and Role Assignments).

### 🚀 Step-by-Step Deployment

#### 1. Setup Backend (Important)
*   **Current State**: The `root/backed.tf` file is currently empty. This means Terraform will store state **locally** on your machine.
*   **Recommendation**: For a team, configure a remote backend (Azure Blob Storage) in this file to share the state.

#### 2. Initialize Terraform
Navigate to the root directory:
```bash
cd root
terraform init
```

#### 3. Select Environment (Workspace)
Create or select the workspace for the environment you want to deploy (dev, uat, prod):
```bash
# Create specific workspace if it doesn't exist
terraform workspace new dev

# Or select existing
terraform workspace select dev
```

#### 4. Plan
Check what Terraform will create. You usually need to pass the subscription ID.
```bash
terraform plan -var="subscription_id=YOUR_SUBS_ID" -out=tfplan
```

#### 5. Apply
Execute the changes.
```bash
terraform apply tfplan
```

## 5. Post-Deployment Verification
1.  Go to the **Azure Portal** -> Resource Group (e.g., `lakehouse-dev-rg`).
2.  Check for:
    *   **Databricks Service**: Launch the workspace.
    *   **Storage Account**: Check that containers `raw`, `bronze` etc. exist.
3.  Go to **Databricks Workpsace** -> **Catalog**.
    *   Verify **External Locations** are created and "Test Connection" works.
    *   Verify the `schema_bronze` (defined in locals) exists in your catalog.
