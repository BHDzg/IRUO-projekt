# =============================================================================
# NSG + ASG spoke mreze (least-privilege):
#   * SSH  <- samo iz sredisnjice (pristupnik/voditelj) prema ASG-u moodle
#   * HTTP <- samo unutar vlastitog VNet-a (interni balanser)
#   * probe <- servisna oznaka AzureLoadBalancer
#   * sve ostalo prema unutra eksplicitno odbijeno
# =============================================================================

resource "azurerm_application_security_group" "moodle" {
  name                = "${var.prefiks}-${var.vlasnik}-asg-moodle"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.meta
}

resource "azurerm_network_security_group" "aplikacija" {
  name                = "${var.prefiks}-${var.vlasnik}-nsg-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.meta
}

resource "azurerm_network_security_rule" "ssh_iz_sredisnjice" {
  name                                       = "Dozvoli-Mgmt-SSH"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = var.hub_cidr
  destination_application_security_group_ids = [azurerm_application_security_group.moodle.id]
  resource_group_name                        = azurerm_resource_group.rg.name
  network_security_group_name                = azurerm_network_security_group.aplikacija.name
}

resource "azurerm_network_security_rule" "http_unutar_vneta" {
  name                                       = "Dozvoli-VNet-HTTP"
  priority                                   = 120
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "80"
  source_address_prefix                      = var.vnet_cidr
  destination_application_security_group_ids = [azurerm_application_security_group.moodle.id]
  resource_group_name                        = azurerm_resource_group.rg.name
  network_security_group_name                = azurerm_network_security_group.aplikacija.name
}

resource "azurerm_network_security_rule" "probe_balansera" {
  name                        = "Dozvoli-AzureLB-Probe"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aplikacija.name
}

resource "azurerm_network_security_rule" "odbij_ostalo" {
  name                        = "Odbij-Ostali-Ulazni"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.aplikacija.name
}

resource "azurerm_subnet_network_security_group_association" "aplikacija" {
  subnet_id                 = azurerm_subnet.aplikacija.id
  network_security_group_id = azurerm_network_security_group.aplikacija.id
}
