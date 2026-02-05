# Azure Databricks Lakehouse – Terraform Infrastructure

## 📌 Overview

This repository contains **Terraform code to provision an Azure Databricks Lakehouse platform** using **Unity Catalog** as the governance layer.

The project is designed to:
- Deploy **Azure infrastructure** (Resource Group, Storage, Databricks Workspace)
- Enable **Unity Catalog** with managed identities
- Create **external locations** for Bronze / Silver / Gold / Raw
- Deploy **Delta Live Tables (DLT) pipelines** publishing to Unity Catalog
- Support **multiple environments** (`dev`, `uat`, `prod`) using **Terraform workspaces**
- Be fully **CI/CD ready**

---

## 🏗️ Architecture

### Azure Resources
- **Single Resource Group per environment**
- **Azure Databricks Workspace (Premium)**
- **ADLS Gen2 Storage Account**
  - Containers:
    - `raw`
    - `bronze`
    - `silver`
    - `gold`
- **Databricks Access Connector** (Managed Identity)
- **RBAC assignments** for Unity Catalog access

### Databricks / Unity Catalog
- **Unity Catalog Metastore** (shared per region)
- **Metastore assignment** to workspace
- **Storage Credential** using Access Connector
- **External Locations** (one per container)
- **Catalog + Schemas**
- **DLT Pipelines** publishing to Unity Catalog

---

## 📂 Repository Structure

```text
.
├── root/
│   ├── main.tf              # Root module wiring
│   ├── providers.tf         # Azure & Databricks providers
│   ├── variables.tf
│   ├── locals.tf            # Environment-aware naming
│   ├── outputs.tf
│
├── modules/
│   ├── resource_group/
│   ├── databricks_workspace/
│   ├── access_connector/
│   ├── storage/
│   ├── unity_catalog/
│   ├── external_locations/
│   └── dlt_pipeline/
│
├── env/
│   ├── dev.tfvars
│   ├── uat.tfvars
│   └── prod.tfvars
│
└── README.md
