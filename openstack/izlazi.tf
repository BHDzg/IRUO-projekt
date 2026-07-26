output "pristupnik_javna_adresa" {
  description = "Javna (floating) IP adresa pristupnika — jedini ulaz"
  value       = openstack_networking_floatingip_v2.pristupnik.address
}

output "voditelj_mgmt_adresa" {
  description = "Adresa voditeljevog racunala u upravljackoj mrezi"
  value       = openstack_compute_instance_v2.voditelj.network[0].fixed_ip_v4
}

output "okoline_programera" {
  description = "Sazetak okoline svakog programera"
  value = { for n, m in module.okolina : n => {
    podmreza       = m.podmreza_cidr
    moodle_adrese  = m.adrese_instanci
    balanser_vip   = m.balanser_vip
    swift_spremnik = m.spremnik_objekata
    nfs_izvoz      = m.nfs_izvoz
  } }
}

output "pocetne_lozinke" {
  description = "Pocetne lozinke Keystone racuna (terraform output -json pocetne_lozinke)"
  value       = { for n, l in random_password.lozinka : n => l.result }
  sensitive   = true
}
