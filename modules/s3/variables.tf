variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = true
}

variable "force_destroy_bucket" {
  description = "Allow bucket destruction even with objects inside"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "enable_inventory" {
  description = "Enable S3 Inventory for daily bucket reports"
  type        = bool
  default     = false
}

variable "inventory_prefix" {
  description = "Prefix for inventory reports in the bucket"
  type        = string
  default     = "inventory"
}

variable "enable_object_lock" {
  description = "Enable S3 Object Lock for compliance"
  type        = bool
  default     = false
}

variable "transition_to_glacier_days" {
  description = "Days before transitioning objects to Glacier"
  type        = number
  default     = 180
}

variable "enable_block_public_access" {
  description = "Block all public access to the bucket (recommended)"
  type        = bool
  default     = true
}
