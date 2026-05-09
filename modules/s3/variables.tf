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
