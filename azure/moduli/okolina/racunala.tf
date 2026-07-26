# =============================================================================
# Moodle VM-ovi (moodle-a, moodle-b — Standard_B2s = 2 vCPU / 4 GB),
# svaki s dva diska: OS + podatkovni managed disk (LUN 0).
# =============================================================================

resource "azurerm_network_interface" "moodle" {
  for_each            = local.instance
  name                = "${var.prefiks}-${var.vlasnik}-moodle-${each.key}-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.meta

  ip_configuration {
    name                          = "glavna"
    subnet_id                     = azurerm_subnet.aplikacija.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "moodle" {
  for_each                      = local.instance
  network_interface_id          = azurerm_network_interface.moodle[each.key].id
  application_security_group_id = azurerm_application_security_group.moodle.id
}

resource "azurerm_linux_virtual_machine" "moodle" {
  for_each              = local.instance
  name                  = "${var.prefiks}-${var.vlasnik}-moodle-${each.key}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.velicina
  admin_username        = var.admin_racun
  network_interface_ids = [azurerm_network_interface.moodle[each.key].id]
  tags                  = merge(local.meta, { node = each.key })

  custom_data = base64encode(templatefile("${path.module}/predlosci/moodle.yaml.tftpl", {
    ime_racunala = "${var.vlasnik}-moodle-${each.key}"
    racun        = azurerm_storage_account.pohrana.name
    kljuc_racuna = azurerm_storage_account.pohrana.primary_access_key
    share        = azurerm_storage_share.sigkopije.name
    spremnik     = azurerm_storage_container.objekti.name
  }))

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }

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

resource "azurerm_virtual_machine_data_disk_attachment" "podatkovni" {
  for_each           = local.instance
  managed_disk_id    = azurerm_managed_disk.podatkovni[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.moodle[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}
