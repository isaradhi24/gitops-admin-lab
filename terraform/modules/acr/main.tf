resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku           = "Basic"
  admin_enabled = false

  tags = {
    "Environment" = var.environment
    "project"     = "gitops-admin-lab"
    "managed_by"  = "Terraform"
  }
}
