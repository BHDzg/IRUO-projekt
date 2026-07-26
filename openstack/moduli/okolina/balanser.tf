# =============================================================================
# Interni Octavia balanser ispred Moodle instanci.
#   * VIP u podmrezi programera (nije javno dostupan)
#   * ROUND_ROBIN + SOURCE_IP session persistence: Moodle drzi sesiju lokalno,
#     pa isti klijent uvijek ide na istu instancu (bez odjava korisnika)
#   * aktivni HTTP nadzor na /status.html
# =============================================================================

resource "openstack_lb_loadbalancer_v2" "balanser" {
  name          = "${var.prefiks}-${var.vlasnik}-balanser"
  description   = "Interni balanser Moodle instanci (${var.vlasnik})"
  vip_subnet_id = openstack_networking_subnet_v2.podmreza.id
  tags          = local.oznake_lista
}

resource "openstack_lb_listener_v2" "http" {
  name            = "${var.prefiks}-${var.vlasnik}-balanser-slusac"
  loadbalancer_id = openstack_lb_loadbalancer_v2.balanser.id
  protocol        = "HTTP"
  protocol_port   = 80
}

resource "openstack_lb_pool_v2" "http" {
  name        = "${var.prefiks}-${var.vlasnik}-balanser-bazen"
  listener_id = openstack_lb_listener_v2.http.id
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"

  persistence {
    type = "SOURCE_IP"
  }
}

resource "openstack_lb_member_v2" "moodle" {
  for_each      = openstack_compute_instance_v2.moodle
  name          = "${var.prefiks}-${var.vlasnik}-balanser-clan-${each.key}"
  pool_id       = openstack_lb_pool_v2.http.id
  subnet_id     = openstack_networking_subnet_v2.podmreza.id
  address       = each.value.network[0].fixed_ip_v4
  protocol_port = 80
}

resource "openstack_lb_monitor_v2" "http" {
  name        = "${var.prefiks}-${var.vlasnik}-balanser-nadzor"
  pool_id     = openstack_lb_pool_v2.http.id
  type        = "HTTP"
  url_path    = "/status.html"
  delay       = 12
  timeout     = 4
  max_retries = 3
}
