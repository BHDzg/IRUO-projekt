output "mreza_id" {
  value = openstack_networking_network_v2.mreza.id
}

output "podmreza_cidr" {
  value = var.podmreza_cidr
}

output "adrese_instanci" {
  value = { for n, i in openstack_compute_instance_v2.moodle : n => i.network[0].fixed_ip_v4 }
}

output "balanser_vip" {
  value = openstack_lb_loadbalancer_v2.balanser.vip_address
}

output "spremnik_objekata" {
  value = openstack_objectstorage_container_v1.objekti.name
}

output "nfs_izvoz" {
  value = try(openstack_sharedfilesystem_share_v2.sigkopije.export_locations[0].path, "")
}
