resource "yandex_dns_zone" "main" {
  name        = "effervescence-ru"
  description = "Public DNS zone for effervescence.ru"
  zone        = "effervescence.ru."
  public      = true
}

resource "yandex_dns_recordset" "app" {
  zone_id = yandex_dns_zone.main.id
  name    = "app.effervescence.ru."
  type    = "A"
  ttl     = 300
  data    = [yandex_compute_instance.worker.network_interface[0].nat_ip_address]
}