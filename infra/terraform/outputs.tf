output "control_plane_public_ip" {
  description = "Control-plane VM public IP address"
  value       = yandex_compute_instance.control_plane.network_interface[0].nat_ip_address
}

output "worker_public_ip" {
  description = "Worker VM public IP address"
  value       = yandex_compute_instance.worker.network_interface[0].nat_ip_address
}

output "control_plane_ssh_command" {
  description = "SSH command for connecting to control-plane VM"
  value       = "ssh ${var.ssh_user}@${yandex_compute_instance.control_plane.network_interface[0].nat_ip_address}"
}

output "worker_ssh_command" {
  description = "SSH command for connecting to worker VM"
  value       = "ssh ${var.ssh_user}@${yandex_compute_instance.worker.network_interface[0].nat_ip_address}"
}