# Output variables for Resource Group module

output "resource_name" {
  value       = azurerm_resource_group.resource_group.name
  description = "Name of the created Resource Group"
}

output "location" {
  value       = azurerm_resource_group.resource_group.location
  description = "Location of the created Resource Group"
}