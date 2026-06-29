data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "control_plane" {
  name        = var.control_plane_name
  hostname    = var.control_plane_name
  platform_id = var.vm_platform_id
  zone        = var.zone

  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = var.vm_disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kubernetes.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_user              = var.ssh_user
      ssh_public_key        = trimspace(file(var.ssh_public_key_path))
      ssh_deploy_public_key = trimspace(file(var.ssh_deploy_public_key_path))
    })
  }

  scheduling_policy {
    preemptible = false
  }
}

resource "yandex_compute_instance" "worker" {
  name                      = var.worker_name
  hostname                  = var.worker_name
  platform_id               = var.vm_platform_id
  zone                      = var.zone
  allow_stopping_for_update = true

  resources {
    cores         = var.vm_cores
    memory        = var.worker_memory
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = var.vm_disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kubernetes.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_user              = var.ssh_user
      ssh_public_key        = trimspace(file(var.ssh_public_key_path))
      ssh_deploy_public_key = trimspace(file(var.ssh_deploy_public_key_path))
    })
  }

  scheduling_policy {
    preemptible = false
  }
}