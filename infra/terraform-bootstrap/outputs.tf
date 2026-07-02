output "state_bucket_name" {
  description = "Object Storage bucket for Terraform state"
  value       = yandex_storage_bucket.tfstate.bucket
}

output "state_key" {
  description = "Recommended key for main infra Terraform state"
  value       = "${var.state_key_prefix}/terraform.tfstate"
}

output "s3_endpoint" {
  description = "Yandex Object Storage S3 endpoint"
  value       = "https://storage.yandexcloud.net"
}

output "backend_service_account_id" {
  description = "Service account ID for Terraform S3 backend credentials"
  value       = yandex_iam_service_account.tfstate.id
}

output "backend_service_account_name" {
  description = "Service account name for Terraform S3 backend credentials"
  value       = yandex_iam_service_account.tfstate.name
}
