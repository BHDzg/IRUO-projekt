# =============================================================================
# Pristupni sloj: PRISTUPNIK (jump host / bastion) + racunalo VODITELJA
#   * pristupnik je JEDINA javno dostupna masina (floating IP)
#   * voditeljevo racunalo dobiva mreznu karticu u mrezi SVAKOG programera
#     pa se s njega SSH-om dolazi do svih instanci; IP forwarding je iskljucen
#     (cloud-init) pa ono NE moze rutati promet izmedju mreza programera
# =============================================================================

resource "openstack_compute_keypair_v2" "lab" {
  name       = "${local.prefiks}-mgmt-kljuc"
  public_key = var.javni_ssh_kljuc
}

# --- Upravljacka (mgmt) mreza ---
resource "openstack_networking_network_v2" "mgmt" {
  name = "${local.prefiks}-mgmt-mreza"
  tags = local.oznake_lista
}

resource "openstack_networking_subnet_v2" "mgmt" {
  name            = "${local.prefiks}-mgmt-podmreza"
  network_id      = openstack_networking_network_v2.mgmt.id
  cidr            = local.mgmt_cidr
  ip_version      = 4
  dns_nameservers = var.dns_posluzitelji
  tags            = local.oznake_lista
}

resource "openstack_networking_router_v2" "mgmt" {
  name                = "${local.prefiks}-mgmt-usmjernik"
  external_network_id = data.openstack_networking_network_v2.vanjska.id
  tags                = local.oznake_lista
}

resource "openstack_networking_router_interface_v2" "mgmt" {
  router_id = openstack_networking_router_v2.mgmt.id
  subnet_id = openstack_networking_subnet_v2.mgmt.id
}

# --- Sigurnosna grupa pristupnika: jedini javni SSH ulaz ---
resource "openstack_networking_secgroup_v2" "pristupnik" {
  name        = "${local.prefiks}-mgmt-sg-pristupnik"
  description = "Pristupnik (bastion) — jedini javni SSH ulaz u laboratorij"
  tags        = local.oznake_lista
}

resource "openstack_networking_secgroup_rule_v2" "pristupnik_ssh" {
  security_group_id = openstack_networking_secgroup_v2.pristupnik.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "SSH s interneta — iskljucivo na pristupnik"
}

# --- Sigurnosna grupa voditeljevog racunala: SSH samo iz mgmt mreze ---
resource "openstack_networking_secgroup_v2" "voditelj" {
  name        = "${local.prefiks}-mgmt-sg-voditelj"
  description = "Racunalo voditelja — SSH iskljucivo s pristupnika"
  tags        = local.oznake_lista
}

resource "openstack_networking_secgroup_rule_v2" "voditelj_ssh" {
  security_group_id = openstack_networking_secgroup_v2.voditelj.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = local.mgmt_cidr
  description       = "SSH iz upravljacke mreze"
}

# --- Pristupnik ---
resource "openstack_networking_port_v2" "pristupnik" {
  name               = "${local.prefiks}-mgmt-pristupnik-port"
  network_id         = openstack_networking_network_v2.mgmt.id
  security_group_ids = [openstack_networking_secgroup_v2.pristupnik.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.mgmt.id
  }
}

resource "openstack_compute_instance_v2" "pristupnik" {
  name        = "${local.prefiks}-mgmt-pristupnik"
  flavor_name = var.velicina_pristupnik
  image_name  = var.slika
  key_pair    = openstack_compute_keypair_v2.lab.name
  user_data   = file("${path.module}/cloud-init/pristupnik.yaml")
  metadata    = merge(local.meta_zajednicko, { owner = "mgmt", role = "bastion" })

  network {
    port = openstack_networking_port_v2.pristupnik.id
  }

  depends_on = [openstack_networking_router_interface_v2.mgmt]
}

resource "openstack_networking_floatingip_v2" "pristupnik" {
  pool        = var.vanjska_mreza
  description = "Jedina javna adresa laboratorija (pristupnik)"
  tags        = local.oznake_lista
}

resource "openstack_networking_floatingip_associate_v2" "pristupnik" {
  floating_ip = openstack_networking_floatingip_v2.pristupnik.address
  port_id     = openstack_networking_port_v2.pristupnik.id
}

# --- Centralno racunalo DevOps voditelja (NIC u svakoj mrezi programera) ---
resource "openstack_compute_instance_v2" "voditelj" {
  name            = "${local.prefiks}-mgmt-voditelj"
  flavor_name     = var.velicina_pristupnik
  image_name      = var.slika
  key_pair        = openstack_compute_keypair_v2.lab.name
  security_groups = [openstack_networking_secgroup_v2.voditelj.name]
  user_data       = file("${path.module}/cloud-init/pristupnik.yaml")
  metadata        = merge(local.meta_zajednicko, { owner = "mgmt", role = "devops_lead" })

  network {
    uuid = openstack_networking_network_v2.mgmt.id
  }

  dynamic "network" {
    for_each = module.okolina
    content {
      uuid = network.value.mreza_id
    }
  }

  depends_on = [openstack_networking_router_interface_v2.mgmt]
}
