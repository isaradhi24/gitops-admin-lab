output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.rg.name
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "ACR login server for Docker push and pull"
  value       = module.acr.acr_login_server
}

output "acr_id" {
  description = "ACR resource ID for Azure RBAC"
  value       = module.acr.acr_id
}
