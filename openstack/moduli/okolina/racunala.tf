# =============================================================================
# Moodle instance (moodle-a, moodle-b, ...), svaka s DVA diska:
#   * OS disk iz cloud slike (Rocky Linux 9)
#   * podatkovni Cinder disk (cloud-init: GPT + XFS + trajni mount)
# Cloud-init dodatno montira NFS za sigurnosne kopije i postavlja web stack.
# =============================================================================

resource "openstack_compute_instance_v2" "moodle" {
  for_each        = local.instance
  name            = "${var.prefiks}-${var.vlasnik}-moodle-${each.key}"
  flavor_name     = var.velicina
  image_name      = var.slika
  key_pair        = var.kljuc
  security_groups = [openstack_networking_secgroup_v2.moodle.name]
  power_state     = "active"

  metadata = merge(local.meta, { node = each.key })

  user_data = templatefile("${path.module}/predlosci/moodle.yaml.tftpl", {
    ime_racunala   = "${var.vlasnik}-moodle-${each.key}"
    podatkovni_dev = "/dev/vdb"
    nfs_izvoz      = try(openstack_sharedfilesystem_share_v2.sigkopije.export_locations[0].path, "")
    spremnik       = openstack_objectstorage_container_v1.objekti.name
  })

  network {
    uuid = openstack_networking_network_v2.mreza.id
  }

  depends_on = [openstack_networking_router_interface_v2.veza]
}

resource "openstack_compute_volume_attach_v2" "podatkovni" {
  for_each    = local.instance
  instance_id = openstack_compute_instance_v2.moodle[each.key].id
  volume_id   = openstack_blockstorage_volume_v3.podatkovni[each.key].id
}
