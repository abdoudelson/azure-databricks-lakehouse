variable "name" {}
variable "pipeline_storage" {}
variable "continuous" {
  type = bool
}
variable "catalog" {
  type        = string
  description = "Unity Catalog catalog to publish to"
}

variable "schema" {
  type        = string
  description = "Unity Catalog schema inside the catalog"
}
