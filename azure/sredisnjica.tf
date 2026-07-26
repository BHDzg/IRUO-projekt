# =============================================================================
# SREDISNJICA (hub) — zajednicki dio hub-and-spoke topologije:
#   * hub resource grupa + hub VNet
#   * PRISTUPNIK (jump host) — jedini resurs s javnom IP adresom
#   * racunalo VODITELJA — kroz VNet peering SSH-om dolazi do svih VM-ova
# Spoke mreze peerane su ISKLJUCIVO na sredisnjicu (nikad medjusobno), a
# allow_forwarded_traffic=false onemogucuje tranzit — programeri su izolirani.
# =============================================================================

resource "azurerm_resource_group" "hub" {
  name     = "${local.prefiks}-mgmt-rg"
  location = var.regija
  tags     = local.meta
}

resource "azurerm_virtual_network" "hub" {
  name                = "${local.prefiks}-mgmt-vnet"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = [local.hub_cidr]
  tags                = local.meta
}

resource "azurerm_subnet" "mgmt" {
  name                 = "${local.prefiks}-mgmt-podmreza"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(local.hub_cidr, 2, 0)]
}

# --- ASG-ovi i NSG sredisnjice ---
resource "azurerm_application_security_group" "pristupnik" {
  name                = "${local.prefiks}-mgmt-asg-pristupnik"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.meta
}

resource "azurerm_application_security_group" "voditelj" {
  name                = "${local.prefiks}-mgmt-asg-voditelj"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.meta
}

resource "azurerm_network_security_group" "mgmt" {
  name                = "${local.prefiks}-mgmt-nsg"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.meta
}

resource "azurerm_network_security_rule" "internet_na_pristupnik" {
  name                                       = "Dozvoli-Internet-SSH-SamoPristupnik"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "Internet"
  destination_application_security_group_ids = [azurerm_application_security_group.pristupnik.id]
  resource_group_name                        = azurerm_resource_group.hub.name
  network_security_group_name                = azurerm_network_security_group.mgmt.name
}

resource "azurerm_network_security_rule" "pristupnik_na_voditelja" {
  name                                       = "Dozvoli-Pristupnik-SSH-Voditelj"
  priority                                   = 120
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_application_security_group_ids      = [azurerm_application_security_group.pristupnik.id]
  destination_application_security_group_ids = [azurerm_application_security_group.voditelj.id]
  resource_group_name                        = azurerm_resource_group.hub.name
  network_security_group_name                = azurerm_network_security_group.mgmt.name
}

resource "azurerm_network_security_rule" "odbij_ostalo_mgmt" {
  name                        = "Odbij-Ostali-Ulazni"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hub.name
  network_security_group_name = azurerm_network_security_group.mgmt.name
}

resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

# --- Pristupnik (jedina javna IP adresa) ---
resource "azurerm_public_ip" "pristupnik" {
  name                = "${local.prefiks}-mgmt-pristupnik-pip"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.meta
}

resource "azurerm_network_interface" "pristupnik" {
  name                = "${local.prefiks}-mgmt-pristupnik-nic"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.meta

  ip_configuration {
    name                          = "glavna"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pristupnik.id
  }
}

resource "azurerm_network_interface_application_security_group_association" "pristupnik" {
  network_interface_id          = azurerm_network_interface.pristupnik.id
  application_security_group_id = azurerm_application_security_group.pristupnik.id
}

resource "azurerm_linux_virtual_machine" "pristupnik" {
  name                  = "${local.prefiks}-mgmt-pristupnik"
  resource_group_name   = azurerm_resource_group.hub.name
  location              = azurerm_resource_group.hub.location
  size                  = var.velicina_mgmt
  admin_username        = var.admin_racun
  network_interface_ids = [azurerm_network_interface.pristupnik.id]
  custom_data           = base64encode(file("${path.module}/cloud-init/pristupnik.yaml"))
  tags                  = merge(local.meta, { owner = "mgmt", role = "bastion" })

  admin_ssh_key {
    username   = var.admin_racun
    public_key = var.javni_ssh_kljuc
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.slika.publisher
    offer     = var.slika.offer
    sku       = var.slika.sku
    version   = var.slika.version
  }

  dynamic "plan" {
    for_each = var.slika_ima_plan ? [1] : []
    content {
      name      = var.slika.sku
      product   = var.slika.offer
      publisher = var.slika.publisher
    }
  }
}

# --- Racunalo voditelja ---
resource "azurerm_network_interface" "voditelj" {
  name                = "${local.prefiks}-mgmt-voditelj-nic"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = local.meta

  ip_configuration {
    name                          = "glavna"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "voditelj" {
  network_interface_id          = azurerm_network_interface.voditelj.id
  application_security_group_id = azurerm_application_security_group.voditelj.id
}

resource "azurerm_linux_virtual_machine" "voditelj" {
  name                  = "${local.prefiks}-mgmt-voditelj"
  resource_group_name   = azurerm_resource_group.hub.name
  location              = azurerm_resource_group.hub.location
  size                  = var.velicina_mgmt
  admin_username        = var.admin_racun
  network_interface_ids = [azurerm_network_interface.voditelj.id]
  custom_data           = base64encode(file("${path.module}/cloud-init/pristupnik.yaml"))
  tags                  = merge(local.meta, { owner = "mgmt", role = "devops_lead" })

  admin_ssh_key {
    username   = var.admin_racun
    public_key = var.javni_ssh_kljuc
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.slika.publisher
    offer     = var.slika.offer
    sku       = var.slika.sku
    version   = var.slika.version
  }

  dynamic "plan" {
    for_each = var.slika_ima_plan ? [1] : []
    content {
      name      = var.slika.sku
      product   = var.slika.offer
      publisher = var.slika.publisher
    }
  }
}

# --- Sredisnjica -> spoke peering ---
resource "azurerm_virtual_network_peering" "hub_prema_spoke" {
  for_each                     = module.okolina
  name                         = "veza-mgmt-prema-${each.key}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = each.value.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
}
