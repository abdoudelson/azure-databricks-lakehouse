resource "databricks_job" "bronze_ingestion" {
  name = "bronze-autoloader"

  job_cluster {
    job_cluster_key = "bronze_cluster"

    new_cluster {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = var.node_type_id
      num_workers   = var.is_prod ? 4 : 1
    }
  }

  task {
    task_key        = "ingest_gtfs"
    job_cluster_key = "bronze_cluster"

    notebook_task {
      notebook_path = "/Repos/bronze/gtfs_autoloader"
    }
  }
}
