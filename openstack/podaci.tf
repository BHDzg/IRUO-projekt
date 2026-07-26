# Postojeci resursi oblaka (samo referenca, ne kreiraju se)
data "openstack_networking_network_v2" "vanjska" {
  name = var.vanjska_mreza
}

data "openstack_identity_role_v3" "member" {
  name = "member"
}

data "openstack_identity_role_v3" "admin" {
  name = "admin"
}
