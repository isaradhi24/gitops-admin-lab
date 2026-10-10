resource "azurerm_resource_group" "rg" {
  name     = "rg-gitops-admin-dev"
  location = "eastus"

  tags = {
    environment = "dev"
    project     = "gitops-admin-lab"
    manager     = "terraform"
  }
}

module "acr" {
  source = "../../modules/acr"

  acr_name            = "gitopsadminacr12345"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  environment         = "dev"
}
