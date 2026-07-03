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
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name)) &&
      !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.state_bucket_name))
    )
    error_message = "state_bucket_name must be 3-63 lowercase letters, numbers, or hyphens and must not be IP-like."
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

variable "state_kms_key_name" {
  description = "KMS key used to encrypt Terraform state objects"
  type        = string
  default     = "mainplatform-tfstate-key"

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{1,61}[a-z0-9]$", var.state_kms_key_name))
    error_message = "state_kms_key_name must be 3-63 chars, lowercase, and start with a letter."
  }
}

variable "state_kms_rotation_period" {
  description = "KMS key rotation period"
  type        = string
  default     = "8760h"
}

variable "state_lockbox_secret_name" {
  description = "Lockbox secret used for backend static access credentials"
  type        = string
  default     = "mainplatform-tfstate-credentials"

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{1,61}[a-z0-9]$", var.state_lockbox_secret_name))
    error_message = "state_lockbox_secret_name must be 3-63 chars, lowercase, and start with a letter."
  }
}

variable "state_bucket_max_size" {
  description = "Maximum bucket size in bytes"
  type        = number
  default     = 1073741824

  validation {
    condition     = var.state_bucket_max_size >= 104857600
    error_message = "state_bucket_max_size must be at least 100 MiB."
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

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "1001-Night"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
  default     = "petProject-mainPlatform"
}

variable "terraform_ci_service_account_name" {
  description = "Service account used by Terraform GitHub Actions"
  type        = string
  default     = "mainplatform-terraform-ci"
}

variable "github_wif_name" {
  description = "GitHub Actions workload identity federation name"
  type        = string
  default     = "mainplatform-github-actions"
}
