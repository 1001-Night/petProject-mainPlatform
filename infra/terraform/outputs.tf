output "network_id" {
  description = "Created VPC network ID"
  value       = yandex_vpc_network.main.id
}

output "subnet_id" {
  description = "Created subnet ID"
  value       = yandex_vpc_subnet.main.id
}