provider "azurerm" {
  features {}
  # Prazno = koristi se ARM_SUBSCRIPTION_ID varijabla okoline
  subscription_id = var.pretplata_id != "" ? var.pretplata_id : null
}

provider "azuread" {}
