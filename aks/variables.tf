# commen
variable "aks_name" {
  type        = string
  description = "The name of the AKS cluster."
}

variable "aks_location" {
  type        = string
  description = "The azure region where the AKS cluster is created in"

  validation {
    condition     = contains(["norwayeast", "norwaywest", "westeurope", "northeurope", "europe"], var.aks_location)
    error_message = "The aks_location value must be an aproved location (norwayeast, norwaywest, westeurope, northeurope or europe)."
  }
}

variable "dns_prefix" {
  type        = string
  description = ""
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group the AKS cluster is created in."
}

variable "kubernetes_version" {
  type        = string
  description = "The version of the AKS cluster to use."
}

# default_node_pool
variable "node_count" {
  type        = number
  description = "The number of nodes in the default nodepool for the AKS cluster."
}

variable "vm_size" {
  type        = string
  description = "The size of the Virtual Machine (Standard_DS2_v2)"
}

variable "os_disk_size_gb" {
  type        = number
  description = "The size of the OS Disk which should be used for each agent in the default Node Pool"
}

variable "role_assignment_NetworkContributor_enable" {
  type        = bool
  default     = false
  description = "Enable the role Assignment of the Kubernetes service prinsepal the NetworkContributor role to the subnets in variable 'ilb_subnet_id' and 'vnet_subnet_id'. it also get asigned rolle 'NetworkContributor' on the resource group AKS service is making starting whit MC_."
}

variable "ilb_subnet_id" {
  type        = string
  description = "Subnet ID for virtual network where aks will deploy loadbalenser"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for virtual network where aks will be deployed"
}

variable "max_node_count" {
  type        = number
  description = "The maximum number of nodes which should exist in default Node Pool."
}

variable "min_node_count" {
  type        = number
  description = "The minimum number of nodes which should exist in default Node Pool."
}

variable "api_server_authorized_ip_ranges" {
  type = string
  # default     = ["10.0.0.0/24"]
  description = "The IP ranges to whitelist for incoming traffic to the masters."
}

# role_based_access_control
variable "rbac_admin_groups" {
  type = list(any)
  # Think this must be default as this is the same groupes for all clusters
  # AAD Group pca-aks-cluster-admins(4a17aaff-da6a-444e-93e0-5aeca31c5171) , AAD Group pca-aks-dev-team1(98a7e238-3769-4320-a5a6-83312d059c46)
  default     = ["4a17aaff-da6a-444e-93e0-5aeca31c5171", "98a7e238-3769-4320-a5a6-83312d059c46"]
  description = "AAD Groups (IDS) with gets admin access to AKS cluster."
}

# addon_profile
variable "azurerm_log_analytics_workspace_id" {
  type        = string
  default     = "/subscriptions/4c048428-bdf9-4cd2-9b36-9f8587559286/resourcegroups/hub-rg-logs/providers/microsoft.operationalinsights/workspaces/hub-ws-masterlog"
  description = "The id of the log analytics workspace in the Hub. Alowing the sentral system to colect info about the AKS"
}

# network_profile
variable "network_plugin" {
  type        = string
  default     = "azure"
  description = "Can either be azure or kubenet. azure will use Azure subnet IPs for Pod IPs. Kubenet you need to use the pod-cidr variable below"
}
variable "network_policy" {
  type        = string
  default     = "calico"
  description = "Uses calico by default for network policy"
}
variable "service_cidr" {
  type = string
  #default     = "192.168.0.0/16"
  description = "The IP address CIDR block to be assigned to the service created inside the Kubernetes cluster. If connecting to another peer or to you On-Premises network this CIDR block MUST NOT overlap with existing BGP learned routes"
}
variable "dns_service_ip" {
  type = string
  #default     = "192.168.0.10"
  description = "The IP address that will be assigned to the CoreDNS or KubeDNS service inside of Kubernetes for Service Discovery. Must start at the .10 or higher of the svc-cidr range"
}
variable "docker_bridge_cidr" {
  type = string
  #default     = "172.22.0.1/29"
  description = "The IP address CIDR block to be assigned to the Docker container bridge on each node. If connecting to another peer or to you On-Premises network this CIDR block SHOULD NOT overlap with existing BGP learned routes"
}

# tags
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

# container registry
variable "container_registry_id" {
  type        = string
  default     = "/subscriptions/4c048428-bdf9-4cd2-9b36-9f8587559286/resourceGroups/p-rg-hub-shared/providers/Microsoft.ContainerRegistry/registries/pacrhub0c91ea"
  description = "The id of the sentral container registry in the Hub."
}

# monitor_diagnostic_setting
variable "monitor_diagnostic_setting_enable" {
  type        = bool
  default     = true
  description = "Enable the Monitor Diagnostic Setting."
}