# =============================================================================
# Pohrana programera (obje se automatski montiraju cloud-initom):
#   * OBJEKTNA (Swift spremnik)  — datoteke Moodlea; ACL ogranicen iskljucivo
#     na Keystone tenant programera (least-privilege)
#   * DATOTECNA (Manila NFS)     — sigurnosne kopije; rw pristup dozvoljen
#     samo IP rasponu podmreze programera
#   * + drugi (podatkovni) Cinder disk po instanci
# =============================================================================

resource "openstack_objectstorage_container_v1" "objekti" {
  name = "${var.prefiks}-${var.vlasnik}-objekti"

  metadata = merge(var.oznake, { owner = var.vlasnik })

  container_read  = "${var.tenant_id}:*"
  container_write = "${var.tenant_id}:*"
}

resource "openstack_sharedfilesystem_sharenetwork_v2" "dijeljena" {
  name              = "${var.prefiks}-${var.vlasnik}-sharenet"
  neutron_net_id    = openstack_networking_network_v2.mreza.id
  neutron_subnet_id = openstack_networking_subnet_v2.podmreza.id
}

resource "openstack_sharedfilesystem_share_v2" "sigkopije" {
  name             = "${var.prefiks}-${var.vlasnik}-sigkopije"
  description      = "NFS za sigurnosne kopije (${var.vlasnik})"
  share_proto      = "NFS"
  size             = var.velicina_nfs
  share_network_id = openstack_sharedfilesystem_sharenetwork_v2.dijeljena.id

  metadata = merge(var.oznake, { owner = var.vlasnik })
}

resource "openstack_sharedfilesystem_share_access_v2" "sigkopije_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.sigkopije.id
  access_type  = "ip"
  access_to    = var.podmreza_cidr
  access_level = "rw"
}

resource "openstack_blockstorage_volume_v3" "podatkovni" {
  for_each    = local.instance
  name        = "${var.prefiks}-${var.vlasnik}-podatkovni-${each.key}"
  description = "Podatkovni disk instance moodle-${each.key} (${var.vlasnik})"
  size        = var.velicina_podatkovnog

  metadata = merge(var.oznake, { owner = var.vlasnik })
}
