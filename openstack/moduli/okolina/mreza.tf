# =============================================================================
# Mreza programera: vlastita mreza + podmreza + usmjernik (SNAT izlaz na
# internet). Mreze razlicitih programera nisu ni na koji nacin povezane.
# =============================================================================

locals {
  oznake_lista = [for k, v in var.oznake : "${k}:${v}"]
  meta         = merge(var.oznake, { managed_by = "terraform", owner = var.vlasnik, role = "developer" })
  instance     = toset(var.slova_instanci)
}

resource "openstack_networking_network_v2" "mreza" {
  name = "${var.prefiks}-${var.vlasnik}-mreza"
  tags = local.oznake_lista
}

resource "openstack_networking_subnet_v2" "podmreza" {
  name            = "${var.prefiks}-${var.vlasnik}-podmreza"
  network_id      = openstack_networking_network_v2.mreza.id
  cidr            = var.podmreza_cidr
  ip_version      = 4
  dns_nameservers = var.dns_posluzitelji
  tags            = local.oznake_lista
}

resource "openstack_networking_router_v2" "usmjernik" {
  name                = "${var.prefiks}-${var.vlasnik}-usmjernik"
  external_network_id = var.vanjska_mreza_id
  tags                = local.oznake_lista
}

resource "openstack_networking_router_interface_v2" "veza" {
  router_id = openstack_networking_router_v2.usmjernik.id
  subnet_id = openstack_networking_subnet_v2.podmreza.id
}
