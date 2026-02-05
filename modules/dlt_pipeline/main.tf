resource "databricks_pipeline" "this" {
  name = var.name
  #  storage    = var.pipeline_storage
  continuous = var.continuous
  catalog    = var.catalog

  target = "${var.catalog}.${var.schema}" # Unity Catalog fully qualified

  library {
    notebook {
      path = "/Repos/dlt/transport_pipeline"
    }
  }
}
