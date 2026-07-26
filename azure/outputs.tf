output "pristupnik_javna_adresa" {
  description = "Javna IP adresa pristupnika — jedini ulaz u okolinu"
  value       = azurerm_public_ip.pristupnik.ip_address
}

output "voditelj_privatna_adresa" {
  description = "Privatna adresa voditeljevog racunala"
  value       = azurerm_network_interface.voditelj.private_ip_address
}

output "okoline_programera" {
  description = "Sazetak okoline svakog programera"
  value = { for n, m in module.okolina : n => {
    vnet          = m.vnet_cidr
    moodle_adrese = m.adrese_instanci
    balanser_ip   = m.balanser_ip
    racun_pohrane = m.racun_pohrane
  } }
}

output "pocetne_lozinke" {
  description = "Pocetne lozinke Entra racuna"
  value       = { for n, l in random_password.lozinka : n => l.result }
  sensitive   = true
}
