output "rg_id" {
  value = azurerm_resource_group.rg.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_cidr" {
  value = var.vnet_cidr
}

output "adrese_instanci" {
  value = { for n, nic in azurerm_network_interface.moodle : n => nic.private_ip_address }
}

output "balanser_ip" {
  value = azurerm_lb.balanser.frontend_ip_configuration[0].private_ip_address
}

output "racun_pohrane" {
  value = azurerm_storage_account.pohrana.name
}
