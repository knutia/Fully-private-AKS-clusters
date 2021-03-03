variable "resource_group_name" {
  type        = string
  description = "The name which should be used for this Resource Group."
}

variable "resource_group_location" {
  type        = string
  description = "The azure region where the Resource Group should exist."

  validation {
    condition     = contains(["norwayeast", "norwaywest", "westeurope", "northeurope", "europe"], var.resource_group_location)
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