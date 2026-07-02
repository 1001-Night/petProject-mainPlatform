variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string

  validation {
    condition     = length(trimspace(var.cloud_id)) > 0
    error_message = "cloud_id must not be empty."
  }
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string

  validation {
    condition     = length(trimspace(var.folder_id)) > 0
    error_message = "folder_id must not be empty."
  }
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = can(regex("^ru-central1-[a-d]$", var.zone))
    error_message = "zone must look like ru-central1-a, ru-central1-b, ru-central1-c, or ru-central1-d."
  }
}

variable "yc_token" {
  description = "YC IAM token. Prefer TF_VAR_yc_token instead of terraform.tfvars."
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.yc_token)) > 0
    error_message = "yc_token must not be empty."
  }
}

variable "state_bucket_name" {
  description = "Globally unique Object Storage bucket name for Terraform state"
  type        = string

  validation {
    condition = (
      length(var.state_bucket_name) >= 3 &&
      length(var.state_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.state_bucket_name)) &&
      !strcontains(var.state_bucket_name, "..") &&
      !strcontains(var.state_bucket_name, ".-") &&
      !strcontains(var.state_bucket_name, "-.") &&
      !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.state_bucket_name))
    )
    error_message = "state_bucket_name must be a valid S3 bucket name: 3-63 chars, lowercase letters/numbers/dots/hyphens, no adjacent dots, and not IP-like."
  }
}

variable "state_key_prefix" {
  description = "Prefix inside the bucket for Terraform state files"
  type        = string
  default     = "mainplatform"

  validation {
    condition     = can(regex("^[A-Za-z0-9._/-]+$", var.state_key_prefix)) && !startswith(var.state_key_prefix, "/") && !endswith(var.state_key_prefix, "/")
    error_message = "state_key_prefix must be a relative object-key prefix without leading/trailing slash."
  }
}

variable "state_service_account_name" {
  description = "Service account used by Terraform S3 backend"
  type        = string
  default     = "mainplatform-tfstate-sa"

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{1,61}[a-z0-9]$", var.state_service_account_name))
    error_message = "state_service_account_name must be 3-63 chars, lowercase, and start with a letter."
  }
}

variable "state_bucket_max_size" {
  description = "Maximum bucket size in bytes. 0 means unlimited."
  type        = number
  default     = 0

  validation {
    condition     = var.state_bucket_max_size >= 0
    error_message = "state_bucket_max_size must be 0 or a positive number of bytes."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "How many days to keep old noncurrent state versions"
  type        = number
  default     = 180

  validation {
    condition     = var.noncurrent_version_expiration_days >= 30
    error_message = "Keep old state versions for at least 30 days."
  }
}

variable "labels" {
  description = "Labels for bootstrap resources"
  type        = map(string)
  default = {
    project = "mainplatform"
    managed = "terraform"
    layer   = "bootstrap"
  }
}
