variable "storage_account" {}
variable "containers" {
  type = list(string)
}
variable "prefix" {}
variable "access_connector_id" {}
