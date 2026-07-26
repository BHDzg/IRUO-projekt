# =============================================================================
# Sigurnosna grupa Moodle instanci (least-privilege, stateful, default deny):
#   * SSH  (22) <- samo iz vlastite podmreze (dolazi s voditeljevog NIC-a)
#   * HTTP (80) <- samo iz vlastite podmreze (Octavia VIP)
#   * ICMP      <- iz vlastite podmreze (dijagnostika)
# =============================================================================

resource "openstack_networking_secgroup_v2" "moodle" {
  name        = "${var.prefiks}-${var.vlasnik}-sg-moodle"
  description = "Moodle instance programera ${var.osoba.ime} ${var.osoba.prezime}"
  tags        = local.oznake_lista
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = openstack_networking_secgroup_v2.moodle.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.podmreza_cidr
  description       = "SSH iskljucivo unutar podmreze (voditeljevo racunalo)"
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  security_group_id = openstack_networking_secgroup_v2.moodle.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.podmreza_cidr
  description       = "HTTP od balansera (VIP u istoj podmrezi)"
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  security_group_id = openstack_networking_secgroup_v2.moodle.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = var.podmreza_cidr
  description       = "Ping unutar podmreze"
}
