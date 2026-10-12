resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    project     = "gitops-admin-lab"
    manager     = "terraform"
  }
}

module "acr" {
  source = "../../modules/acr"

  acr_name            = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = var.environment
}
