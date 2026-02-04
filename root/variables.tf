variable "environment" {
  type        = string
  description = "Deployment environment (dev, test, prod)"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}
