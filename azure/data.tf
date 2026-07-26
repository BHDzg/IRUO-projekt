data "azurerm_subscription" "trenutna" {}

data "azuread_domains" "tenant" {
  only_initial = true
}
