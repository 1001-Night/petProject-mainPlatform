variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "mainplatform-network"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "mainplatform-subnet-a"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = list(string)
  default     = ["10.10.0.0/24"]
}

variable "yc_token" {
  description = "YC IAM token"
  type        = string
  sensitive   = true
}