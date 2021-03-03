# ----------------------------------------------------------------------------------------------------------------------
# Module : Resource Group
# Dependencies :
#     - https://registry.terraform.io/providers/hashicorp/helm/latest/docs
# References : 
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.14.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.41.0"
    }
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags     = merge(var.commen_tags, var.tags)
}