# Po jedna potpuno izolirana okolina za svakog programera iz CSV-a.
# Broj okolina ovisi iskljucivo o broju redaka u CSV datoteci.
module "okolina" {
  source   = "./moduli/okolina"
  for_each = local.programeri

  vlasnik   = each.key
  osoba     = each.value
  prefiks   = local.prefiks
  oznake    = var.oznake
  tenant_id = openstack_identity_project_v3.tenant[each.key].id

  slika               = var.slika
  velicina            = var.velicina_moodle
  kljuc               = openstack_compute_keypair_v2.lab.name
  vanjska_mreza_id    = data.openstack_networking_network_v2.vanjska.id
  podmreza_cidr       = local.programer_cidr[each.key]
  dns_posluzitelji    = var.dns_posluzitelji
  velicina_podatkovnog = var.velicina_podatkovnog_gb
  velicina_nfs        = var.velicina_nfs_gb
  slova_instanci      = local.slova
}
