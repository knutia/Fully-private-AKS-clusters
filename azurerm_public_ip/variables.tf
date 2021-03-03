variable "pip_name" {
  type        = string
  description = "The name of the Public IP Address."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group the Public IP Address should be created in."
}

variable "location" {
  type        = string
  description = "The azure region where the Public IP Address should exist"

  validation {
    condition     = contains(["norwayeast", "norwaywest", "westeurope", "northeurope", "europe"], var.location)
    error_message = "The resource_group_location value must be aproved location (norwayeast, norwaywest, westeurope, northeurope or europe)."
  }
}

variable "commen_tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed"
  default = {
    configuration = "terraform"
    system        = "S07373"
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use for the resources that are deployed"
  default     = {}
}

variable "monitor_diagnostic_setting_enable" {
  type        = bool
  default     = false
  description = "Enable the Monitor Diagnostic Setting."
}

variable "pip_diag_name" {
  type        = string
  default     = "EMPTY"
  description = "Name of the Diagnostic Setting. defaults to the pip name"
}

variable "azurerm_log_analytics_workspace_id" {
  type        = string
  default     = "/subscriptions/4c048428-bdf9-4cd2-9b36-9f8587559286/resourcegroups/hub-rg-logs/providers/microsoft.operationalinsights/workspaces/hub-ws-masterlog"
  description = "The id of the log analytics workspace in the Hub. Alowing the sentral system to colect info about the AKS"
}