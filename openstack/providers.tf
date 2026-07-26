# Autentikacija: preporuceno je prije pokretanja izvrsiti `source openrc`
# (provider automatski cita OS_* varijable okoline); alternativno se
# vrijednosti mogu zadati u os-lab.tfvars (vidi os-lab.tfvars.example).
provider "openstack" {
  auth_url            = var.os_auth_url != "" ? var.os_auth_url : null
  user_name           = var.os_korisnik != "" ? var.os_korisnik : null
  password            = var.os_lozinka != "" ? var.os_lozinka : null
  tenant_name         = var.os_projekt != "" ? var.os_projekt : null
  user_domain_name    = var.os_domena
  project_domain_name = var.os_domena
  region              = var.os_regija != "" ? var.os_regija : null
}
