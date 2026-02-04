resource "databricks_pipeline" "this" {
  name       = var.name
  target     = var.target_schema
  storage    = var.pipeline_storage
  continuous = var.continuous

  library {
    notebook {
      path = "/Repos/dlt/transport_pipeline"
    }
  }
}
