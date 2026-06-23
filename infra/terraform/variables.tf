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

variable "vm_name" {
  description = "Kubernetes VM name"
  type        = string
  default     = "mainplatform-k3s"
}

variable "vm_platform_id" {
  description = "Yandex Compute VM platform"
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "VM CPU cores"
  type        = number
  default     = 2
}

variable "vm_core_fraction" {
  description = "Baseline vCPU performance percent"
  type        = number
  default     = 100
}

variable "vm_memory" {
  description = "VM memory in GB"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "VM boot disk size in GB"
  type        = number
  default     = 20
}

variable "ssh_user" {
  description = "SSH user for VM"
  type        = string
  default     = "user1001"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "control_plane_name" {
  description = "Kubernetes control-plane VM name"
  type        = string
  default     = "mainplatform-control-plane"
}

variable "worker_name" {
  description = "Kubernetes worker VM name"
  type        = string
  default     = "mainplatform-worker-1"
}

variable "worker_memory" {
  description = "Worker VM memory in GB"
  type        = number
  default     = 2
}