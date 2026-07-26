# =============================================================================
# Pohrana programera — jedan Storage Account:
#   * BLOB spremnik "objekti"    = objektna pohrana (datoteke Moodlea)
#   * FILE share  "sigkopije"    = datotecna pohrana (sigurnosne kopije)
# Least-privilege:
#   * blob: user-assigned MANAGED IDENTITY na VM-ovima + rola
#     "Storage Blob Data Contributor" iskljucivo na ovom accountu (bez kljuceva)
#   * file share: SMB mount; mrezno ogranicen service endpointom podmreze
# =============================================================================

resource "random_string" "sufiks" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "pohrana" {
  # samo mala slova i brojke, globalno jedinstveno
  name                     = substr(replace("tslab${var.vlasnik}${random_string.sufiks.result}", "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.meta

  network_rules {
    default_action             = "Allow" # strogi rezim: Deny + service endpoint (vidi dokumentaciju)
    virtual_network_subnet_ids = [azurerm_subnet.aplikacija.id]
    bypass                     = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "objekti" {
  name                  = "objekti"
  storage_account_id    = azurerm_storage_account.pohrana.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "sigkopije" {
  name               = "sigkopije"
  storage_account_id = azurerm_storage_account.pohrana.id
  quota              = var.kvota_share
}

resource "azurerm_user_assigned_identity" "vm" {
  name                = "${var.prefiks}-${var.vlasnik}-identitet-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.meta
}

resource "azurerm_role_assignment" "blob_pristup" {
  scope                = azurerm_storage_account.pohrana.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
}

resource "azurerm_managed_disk" "podatkovni" {
  for_each             = local.instance
  name                 = "${var.prefiks}-${var.vlasnik}-podatkovni-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.velicina_podatkovnog
  tags                 = local.meta
}
