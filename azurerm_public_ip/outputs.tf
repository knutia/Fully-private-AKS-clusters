output "pip_id" {
  value       = azurerm_public_ip.pip.id
  description = "Id of the created Public Ip adress"
}

output "pip_name" {
  value       = azurerm_public_ip.pip.name
  description = "Name of the created Public Ip adress"
}