resource "yandex_iam_service_account" "tfstate" {
  name        = var.state_service_account_name
  description = "Service account for Terraform state backend in Object Storage"
  labels      = var.labels
}

resource "yandex_kms_symmetric_key" "tfstate" {
  name                = var.state_kms_key_name
  description         = "KMS key for Terraform state encryption"
  default_algorithm   = "AES_256"
  rotation_period     = var.state_kms_rotation_period
  deletion_protection = true
  labels              = var.labels

  lifecycle {
    prevent_destroy = true
  }
}

resource "yandex_storage_bucket" "tfstate" {
  bucket    = var.state_bucket_name
  folder_id = var.folder_id
  max_size  = var.state_bucket_max_size

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
        kms_master_key_id = yandex_kms_symmetric_key.tfstate.id
        sse_algorithm     = "aws:kms"
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

resource "yandex_storage_bucket_iam_binding" "tfstate_editor" {
  bucket = yandex_storage_bucket.tfstate.bucket
  role   = "storage.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.tfstate.id}",
  ]
}

resource "yandex_kms_symmetric_key_iam_binding" "tfstate_encrypter_decrypter" {
  symmetric_key_id = yandex_kms_symmetric_key.tfstate.id
  role             = "kms.keys.encrypterDecrypter"

  members = [
    "serviceAccount:${yandex_iam_service_account.tfstate.id}",
  ]
}

resource "yandex_lockbox_secret" "tfstate_credentials" {
  name                = var.state_lockbox_secret_name
  description         = "Static access key for Terraform state backend"
  deletion_protection = true
  labels              = var.labels
}

resource "yandex_iam_service_account_static_access_key" "tfstate" {
  service_account_id = yandex_iam_service_account.tfstate.id
  description        = "Static access key for Terraform state backend"

  output_to_lockbox {
    secret_id            = yandex_lockbox_secret.tfstate_credentials.id
    entry_for_access_key = "access_key"
    entry_for_secret_key = "secret_key"
  }

  depends_on = [
    yandex_storage_bucket_iam_binding.tfstate_editor,
    yandex_kms_symmetric_key_iam_binding.tfstate_encrypter_decrypter,
  ]
}
