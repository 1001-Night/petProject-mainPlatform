resource "yandex_vpc_security_group" "kubernetes" {
  name       = "mainplatform-k8s-sg"
  network_id = yandex_vpc_network.main.id

  dynamic "ingress" {
    for_each = toset(var.admin_cidr_blocks)
    iterator = admin_cidr

    content {
      description    = "Temporary SSH bootstrap access"
      protocol       = "TCP"
      port           = 22
      v4_cidr_blocks = [admin_cidr.value]
    }
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Internal Kubernetes node traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.10.0.0/24"]
  }

  egress {
    description    = "Allow all outbound traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}