# =============================================================================
# Entra ID + RBAC (least-privilege)
#   * korisnici i skupine kreiraju se iz CSV-a
#   * PROGRAMER: custom rola "upravljac-napajanja" (read + start/restart/
#     powerOff/deallocate) dodijeljena ISKLJUCIVO na njegovoj resource grupi
#     -> Start/Deallocate samo nad vlastitim VM-ovima, tudje ni ne vidi
#   * VODITELJ (skupina): ugradjena rola Virtual Machine Contributor na svim
#     resource grupama -> kontrola svih instanci
# =============================================================================

resource "random_password" "lozinka" {
  for_each = local.svi
  length   = 22
  special  = true
}

resource "azuread_user" "racun" {
  for_each              = local.svi
  user_principal_name   = "${each.value.nadimak}@${local.entra_domena}"
  display_name          = "${each.value.ime} ${each.value.prezime}"
  mail_nickname         = each.value.nadimak
  password              = random_password.lozinka[each.key].result
  force_password_change = true
}

resource "azuread_group" "programeri" {
  display_name     = "${local.prefiks}-skupina-programeri"
  security_enabled = true
}

resource "azuread_group" "voditelji" {
  display_name     = "${local.prefiks}-skupina-voditelji"
  security_enabled = true
}

resource "azuread_group_member" "programer" {
  for_each         = local.programeri
  group_object_id  = azuread_group.programeri.object_id
  member_object_id = azuread_user.racun[each.key].object_id
}

resource "azuread_group_member" "voditelj" {
  for_each         = local.voditelji
  group_object_id  = azuread_group.voditelji.object_id
  member_object_id = azuread_user.racun[each.key].object_id
}

# --- Custom rola: samo upravljanje stanjem VM-a ---
resource "azurerm_role_definition" "upravljac_napajanja" {
  name        = "${local.prefiks}-upravljac-napajanja"
  scope       = data.azurerm_subscription.trenutna.id
  description = "Citanje VM-ova i start/restart/powerOff/deallocate — bez izmjena infrastrukture"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
    ]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.trenutna.id]
}

resource "azurerm_role_assignment" "programer_svoja_rg" {
  for_each           = local.programeri
  scope              = module.okolina[each.key].rg_id
  role_definition_id = azurerm_role_definition.upravljac_napajanja.role_definition_resource_id
  principal_id       = azuread_user.racun[each.key].object_id
}

locals {
  sve_grupe_resursa = merge(
    { for n, m in module.okolina : n => m.rg_id },
    { mgmt = azurerm_resource_group.hub.id }
  )
}

resource "azurerm_role_assignment" "voditelji_sve_rg" {
  for_each             = local.sve_grupe_resursa
  scope                = each.value
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.voditelji.object_id
}
