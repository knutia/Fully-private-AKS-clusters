output "id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "The ID of the Azure Kubernetes Managed Cluster."
}

output "aks_fqdn" {
  value       = azurerm_kubernetes_cluster.aks.fqdn
  description = "The FQDN of the Azure Kubernetes Managed Cluster."
}

output "aks_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "The Name of the Azure Kubernetes Managed Cluster."
}

output "host" {
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  sensitive   = true
  description = "The HOST NAME of the Azure Kubernetes Managed Cluster."
}

output "client_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate
  sensitive   = true
  description = "The Client Certificate of the Azure Kubernetes Managed Cluster."
}

output "client_key" {
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key
  sensitive   = true
  description = "The Client Key of the Azure Kubernetes Managed Cluster."
}

output "cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate
  sensitive   = true
  description = "The Cluster CA Certificate of the Azure Kubernetes Managed Cluster."
}

output "rg_name" {
  value       = azurerm_kubernetes_cluster.aks.resource_group_name
  description = "The Resource Groupe Name Where the Azure Kubernetes Managed Cluster is created."
}

output "kubelet_identity_client_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
  description = "AKS kubelet_identity client_id"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  description = "AKS kubelet_identity object_id"
}

output "kubelet_identity_user_assigned_identity_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].user_assigned_identity_id
  description = "AKS kubelet_identity user_assigned_identity_id"
}

output "identity_type" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].type
  description = "AKS MI type"
}

output "identity_principal_id" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  description = "AKS MI principal_id"
}

output "identity_tenant_id" {
  value       = azurerm_kubernetes_cluster.aks.identity[0].tenant_id
  description = "AKS MI tenant_id"
}
