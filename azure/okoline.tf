# Po jedna izolirana spoke okolina za svakog programera iz CSV-a.
module "okolina" {
  source   = "./moduli/okolina"
  for_each = local.programeri

  vlasnik = each.key
  osoba   = each.value
  prefiks = local.prefiks
  regija  = var.regija
  oznake  = var.oznake

  vnet_cidr    = local.programer_cidr[each.key]
  hub_cidr     = local.hub_cidr
  hub_vnet_id  = azurerm_virtual_network.hub.id

  velicina        = var.velicina_moodle
  admin_racun     = var.admin_racun
  javni_ssh_kljuc = var.javni_ssh_kljuc
  slika           = var.slika
  slika_ima_plan  = var.slika_ima_plan

  velicina_podatkovnog = var.velicina_podatkovnog_gb
  kvota_share          = var.kvota_share_gb
  slova_instanci       = local.slova
}
