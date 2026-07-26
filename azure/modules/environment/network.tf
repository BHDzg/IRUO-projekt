# =============================================================================
# Spoke mreza programera: vlastita resource grupa i VNet.
# Peering iskljucivo prema sredisnjici; spoke <-> spoke ne postoji.
# =============================================================================

locals {
  meta     = merge(var.oznake, { managed_by = "terraform", owner = var.vlasnik, role = "developer" })
  instance = toset(var.slova_instanci)
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefiks}-${var.vlasnik}-rg"
  location = var.regija
  tags     = local.meta
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefiks}-${var.vlasnik}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet_cidr]
  tags                = local.meta
}

resource "azurerm_subnet" "aplikacija" {
  name                 = "${var.prefiks}-${var.vlasnik}-podmreza-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 1, 0)]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_virtual_network_peering" "spoke_prema_hubu" {
  name                         = "veza-${var.vlasnik}-prema-mgmt"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}
