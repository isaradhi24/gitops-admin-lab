variable "acr_name" {
  description = "Name of the Container Registry"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region where ACR will be created"
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev,qa, uat,or prod"
  type        = string
}
