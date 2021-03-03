# ----------------------------------------------------------------------------------------------------------------------
# Module : Public Ip
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

resource "azurerm_public_ip" "pip" {
  name                = var.pip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.commen_tags, var.tags)
}

resource "azurerm_monitor_diagnostic_setting" "ip" {
  count              = var.monitor_diagnostic_setting_enable ? 1 : 0
  name               = contains([var.pip_diag_name], "EMPTY") ? var.pip_name : var.pip_diag_name
  target_resource_id = azurerm_public_ip.pip.id

  log_analytics_workspace_id = var.azurerm_log_analytics_workspace_id

  log {
    category = "DDoSProtectionNotifications"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "DDoSMitigationFlowLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "DDoSMitigationReports"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}