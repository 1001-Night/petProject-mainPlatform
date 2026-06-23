resource "yandex_vpc_security_group" "k3s" {
  name       = "mainplatform-k3s-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
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
    description    = "Kubernetes API"
    protocol       = "TCP"
    port           = 6443
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