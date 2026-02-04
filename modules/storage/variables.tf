variable "name" {}
variable "rg_name" {}
variable "location" {}
variable "containers" {
  type = list(string)
}
