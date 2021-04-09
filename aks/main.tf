# ----------------------------------------------------------------------------------------------------------------------
# Module : Kubernetes Cluster
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

data "azurerm_subscription" "current" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.aks_location
  dns_prefix          = var.dns_prefix
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  # private_link_enabled = true
  private_cluster_enabled = true

  default_node_pool {
    name                 = "default"
    node_count           = var.node_count
    vm_size              = var.vm_size
    os_disk_size_gb      = var.os_disk_size_gb
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = var.vnet_subnet_id
    orchestrator_version = var.kubernetes_version
    enable_auto_scaling  = true
    max_count            = var.max_node_count
    min_count            = var.min_node_count
  }

  identity {
    type = "SystemAssigned"
  }

  #TODO but what ip range to use?
  #  - The IP ranges to whitelist for incoming traffic to the masters
  # api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  role_based_access_control {
    enabled = true
    // azure_active_directory {
    //   managed                = true
    //   admin_group_object_ids = var.rbac_admin_groups
    //   tenant_id              = data.azurerm_subscription.current.tenant_id
    // }
  }
  addon_profile {
    dynamic "oms_agent" {
      for_each = contains([var.azurerm_log_analytics_workspace_id], "EMPTY") ? [] : [var.azurerm_log_analytics_workspace_id]
      content {
        enabled                    = true
        log_analytics_workspace_id = var.azurerm_log_analytics_workspace_id
      }
    }
    // oms_agent {
    //   enabled = true
    //   #log_analytics_workspace_id = var.azurerm_log_analytics_workspace_id
    //   log_analytics_workspace_id = contains([var.azurerm_log_analytics_workspace_id], "EMPTY") ? null : var.azurerm_log_analytics_workspace_id
    // }
    kube_dashboard {
      enabled = true
    }
    # To be complient whit "ASC auto-provisioning Azure Policy Addon for Kubernetes" policy in azure
    #  - https://docs.microsoft.com/en-ie/azure/governance/policy/concepts/policy-for-kubernetes
    azure_policy {
      enabled = true
    }
  }
  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = "userDefinedRouting"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].vnet_subnet_id,
      windows_profile
    ]
  }

  tags = merge(var.commen_tags, var.tags)

}

// Allow Kubernetes to pull images from sentral Azure container regestry "pacrhub0c91ea" in RG "p-rg-hub-shared" sub "p-sub-hub"
resource "azurerm_role_assignment" "aks_to_acr" {
  count                = contains([var.container_registry_id], "EMPTY") ? 0 : 1
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

// resource "azurerm_role_assignment" "dns_contributor" {
//   count                = contains([var.dns_zone_id], "EMPTY") ? 0 : 1
//   scope                            = var.dns_zone_id
//   role_definition_name             = "DNS Zone Contributor"
//   principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
//   skip_service_principal_aad_check = true # Allows skipping propagation of identity to ensure assignment succeeds.
// }

// Allow Kubernetes service prinsepal to make internal loadbalanser for subnett "x-exp-snet-dc-aks-ilb" in the resource groupe statring whit "MC_" created by AKS and using the subnet "x-exp-snet-dc-aks-nodepool"
resource "azurerm_role_assignment" "aks_to_lib_subnet" {
  count                = var.role_assignment_NetworkContributor_enable ? 1 : 0
  scope                = var.ilb_subnet_id
  role_definition_name = "Network Contributor"
  #principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
resource "azurerm_role_assignment" "aks_to_pool_subnet" {
  count                = var.role_assignment_NetworkContributor_enable ? 1 : 0
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  #principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
data "azurerm_resource_group" "aks_node_resource_group" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
}
resource "azurerm_role_assignment" "aks_to_aks_rg" {
  count                = var.role_assignment_NetworkContributor_enable ? 1 : 0
  scope                = data.azurerm_resource_group.aks_node_resource_group.id
  role_definition_name = "Network Contributor"
  #principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  principal_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}



// Send all log data and metric to the same Log Analytics Workspace as the cluster is conected to."
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count              = var.monitor_diagnostic_setting_enable ? 1 : 0
  name               = var.aks_name
  target_resource_id = azurerm_kubernetes_cluster.aks.id

  log_analytics_workspace_id = var.azurerm_log_analytics_workspace_id

  log {
    category = "kube-apiserver"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "kube-audit"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "kube-audit-admin"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "kube-controller-manager"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "kube-scheduler"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "cluster-autoscaler"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  log {
    category = "guard"
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