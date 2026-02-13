variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "pipeline_repo_url" {
  type        = string
  description = "The URL of the Git repository containing the DLT pipeline code"
}

variable "catalog_name" {
  type        = string
  description = "Unity Catalog catalog name used by schemas and DLT pipelines"
  default     = "main"
}
