resource "yandex_iam_service_account" "tfstate" {
  name        = var.state_service_account_name
  description = "Service account for Terraform state backend in Object Storage"
}

# Terraform S3 backend needs read/write and lock-file delete operations.
# storage.editor is narrower than storage.admin: it cannot manage ACLs or create public buckets.
resource "yandex_resourcemanager_folder_iam_member" "tfstate_storage_editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate.id}"
}

resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.state_bucket_name
  folder_id = var.folder_id

  # 0 means no explicit size limit. Terraform state versions are tiny, but a hard 1 GiB cap
  # can create an avoidable failure mode after long-lived versioning.
  max_size = var.state_bucket_max_size
  labels   = var.labels

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "cleanup-old-state-versions"
    enabled = true

    noncurrent_version_expiration {
      days = var.noncurrent_version_expiration_days
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
