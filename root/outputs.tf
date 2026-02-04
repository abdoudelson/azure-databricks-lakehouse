output "databricks_workspace_url" {
  value = module.databricks_workspace.workspace_url
}

output "environment" {
  value = var.environment
}
