module "networks_rg" {
  source                  = "./azurerm_resource_group"
  resource_group_name     = "dzpraks1_networks"
  resource_group_location = "westeurope"

}

module "kube_rg" {
  source                  = "./azurerm_resource_group"
  resource_group_name     = "dzpraks1_kube"
  resource_group_location = "westeurope"

}

module "hub_vnet" {
  source                  = "./vnet"
  vnet_name               = "hub1-firewalvnet"
  resource_group_name     = module.networks_rg.resource_name
  resource_group_location = module.networks_rg.location
  address_space           = ["10.0.0.0/22"]
  subnet_prefixes         = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/27"]
  subnet_names            = ["AzureFirewallSubnet", "jumpbox-subnet", "GatewaySubnet"]
  tags = {
    configuration = "terraform"
    system        = "S07373"
  }
  depends_on = [module.networks_rg]
}

module "kube_vnet" {
  source                  = "./vnet"
  vnet_name               = "spoke1-kubevnet"
  resource_group_name     = module.networks_rg.resource_name
  resource_group_location = module.networks_rg.location
  address_space           = ["10.0.4.0/22"]
  subnet_prefixes         = ["10.0.4.0/24", "10.0.5.0/24"]
  subnet_names            = ["ing-1-subnet", "aks-2-subnet"]
  subnet_enforce_private_link_endpoint_network_policies = {ing-1-subnet = false, aks-2-subnet = true}
  tags = {
    configuration = "terraform"
    system        = "S07373"
  }
  depends_on = [module.networks_rg]
}


resource "azurerm_virtual_network_peering" "example-1" {
  name                      = "HubToSpoke1"
  resource_group_name       = module.networks_rg.resource_name
  virtual_network_name      = module.hub_vnet.vnet_name
  remote_virtual_network_id = module.kube_vnet.vnet_id
  depends_on                = [module.networks_rg, module.hub_vnet, module.kube_vnet]
  allow_gateway_transit     = true

}

resource "azurerm_virtual_network_peering" "example-2" {
  name                      = "Spoke1ToHub"
  resource_group_name       = module.networks_rg.resource_name
  virtual_network_name      = module.kube_vnet.vnet_name
  remote_virtual_network_id = module.hub_vnet.vnet_id
  depends_on                = [module.networks_rg, module.hub_vnet, module.kube_vnet]
  use_remote_gateways       = true
}

resource "azurerm_public_ip" "example" {
  name                = "dzpraks1"
  location            = module.networks_rg.location
  resource_group_name = module.networks_rg.resource_name
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [module.networks_rg]
}

resource "azurerm_firewall" "example" {
  name                = "dzpraks1"
  location            = module.networks_rg.location
  resource_group_name = module.networks_rg.resource_name

  ip_configuration {
    name                 = "dzpraks1"
    subnet_id            = module.hub_vnet.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.example.id
  }
  depends_on = [module.networks_rg, module.hub_vnet, azurerm_public_ip.example]
}

// FW_PRIVATE_IP = azurerm_firewall.example.ip_configuration.private_ip_address
// KUBE_AGENT_SUBNET_ID = module.kube_vnet.vnet_subnets[1]

resource "azurerm_route_table" "example" {
  name                = "dzpraks1"
  location            = module.networks_rg.location
  resource_group_name = module.networks_rg.resource_name
  route {
    name                   = "dzpraks1"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.example.ip_configuration[0].private_ip_address
  }
  depends_on = [module.networks_rg, azurerm_firewall.example]
}

// resource "azurerm_route" "example" {
//   name                = "dzpraks1"
//   resource_group_name = module.networks_rg.resource_name
//   route_table_name    = azurerm_route_table.example.name
//   address_prefix      = "0.0.0.0/0"
//   next_hop_type       = "VirtualAppliance"
//   next_hop_in_ip_address = azurerm_firewall.example.ip_configuration.private_ip_address
// }

resource "azurerm_subnet_route_table_association" "example" {
  subnet_id      = module.kube_vnet.vnet_subnets[1]
  route_table_id = azurerm_route_table.example.id
  depends_on     = [module.kube_vnet, azurerm_route_table.example]
}

resource "azurerm_firewall_network_rule_collection" "time" {
  name                = "time"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 101
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name        = "allow network"
    description = "aks node time sync rule"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "123",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "UDP",
    ]
  }
}

resource "azurerm_firewall_network_rule_collection" "dns" {
  name                = "dns"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 102
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name        = "allow network"
    description = "aks node dns rule"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "UDP",
    ]
  }
}

resource "azurerm_firewall_network_rule_collection" "servicetags" {
  name                = "servicetags"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 110
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name        = "allow service tags"
    description = "allow service tags"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "AzureContainerRegistry",
      "MicrosoftContainerRegistry",
      "AzureActiveDirectory",
      "AzureMonitor",
    ]

    protocols = [
      "Any",
    ]
  }
}

resource "azurerm_firewall_application_rule_collection" "aksfwar" {
  name                = "aksfwar"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 101
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name = "fqdn"

    source_addresses = [
      "*",
    ]

    target_fqdns = [
      "AzureKubernetesService",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "osupdates" {
  name                = "osupdates"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 102
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name = "allow network"

    source_addresses = [
      "*",
    ]

    target_fqdns = [
      "download.opensuse.org",
      "security.ubuntu.com",
      "packages.microsoft.com",
      "azure.archive.ubuntu.com",
      "changelogs.ubuntu.com",
      "snapcraft.io",
      "api.snapcraft.io",
      "motd.ubuntu.com",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "aksdependencies" {
  name                = "aksdependencies"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 103
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name = "allow network"

    source_addresses = [
      "*",
    ]

    target_fqdns = [
      "*.hcp.westeurope.azmk8s.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "acs-mirror.azureedge.net",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "dockerhub" {
  name                = "dockerhub"
  azure_firewall_name = azurerm_firewall.example.name
  resource_group_name = module.networks_rg.resource_name
  priority            = 104
  action              = "Allow"
  depends_on          = [module.networks_rg, azurerm_firewall.example]

  rule {
    name = "allow network"

    source_addresses = [
      "*",
    ]

    target_fqdns = [
      "*auth.docker.io",
      "*cloudflare.docker.io",
      "*cloudflare.docker.com",
      "*registry-1.docker.io",
    ]

    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}


module "aks" {
  source                          = "./aks"
  aks_name                        = "dzpraks1"
  aks_location                    = module.kube_rg.location
  dns_prefix                      = "dzpraks1"
  resource_group_name             = module.kube_rg.resource_name
  kubernetes_version              = "1.18.10"
  node_count                      = 1
  vm_size                         = "Standard_D4s_v3"
  os_disk_size_gb                 = 30
  ilb_subnet_id                   = "/subscriptions/cf9244f0-70e0-42c0-b545-e21b08c2867a/resourceGroups/t-exp-rg-common-infra/providers/Microsoft.Network/virtualNetworks/t-exp-Shared-Management-vnet/subnets/t-exp-snet-dc-aks-ilb"
  vnet_subnet_id                  = module.kube_vnet.vnet_subnets[1]
  max_node_count                  = 1
  min_node_count                  = 1
  api_server_authorized_ip_ranges = "10.182.128.0/18"
  #rbac_admin_groups                         = ["858aa64d-1b61-415b-aec9-d505442380ba"]
  network_plugin                            = "azure"
  network_policy                            = "calico"
  service_cidr                              = "192.168.0.0/16"
  dns_service_ip                            = "192.168.0.10"
  docker_bridge_cidr                        = "172.22.0.1/29"
  monitor_diagnostic_setting_enable         = false
  role_assignment_NetworkContributor_enable = false
  container_registry_id                     = "EMPTY"
  azurerm_log_analytics_workspace_id        = "EMPTY"
  tags = {
    configuration = "terraform"
    system        = "S07373"
  }
  depends_on = [module.kube_rg, module.kube_vnet, azurerm_firewall_application_rule_collection.aksdependencies]
}

# https://github.com/kumarvna/terraform-azurerm-vpn-gateway
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway
module "vpn-gateway" {
  # source  = "kumarvna/vpn-gateway/azurerm"
  # version = "1.0.0"
  source = "./vpn"

  # Resource Group, location, VNet and Subnet details
  resource_group_name  = module.networks_rg.resource_name
  virtual_network_name = module.hub_vnet.vnet_name
  vpn_gateway_name     = "hub1-firewalvnet-vpn-gw01"

  # client configuration for Point-to-Site VPN Gateway connections
  vpn_client_configuration = {
    address_space        = "172.16.201.0/24"
    vpn_client_protocols = ["SSTP", "IkeV2"]
    certificate          = <<EOF
MIIC5zCCAc+gAwIBAgIQEosePIVAeJNHTJTYY67bRjANBgkqhkiG9w0BAQsFADAW
MRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMTA0MDYxMDIyMjZaFw0yMjA0MDYx
MDQyMjZaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAqstLBzMYZ7feKcCLXxRbTQbMqp46Zb6wG+2mvm62gjk5
66MrHcowTNTdm2FdNRAEFTLQAGceWGRRCPHvtqzOlbOTgB/7nAcZLJldGY+glrl6
4lpcfJ6LHin3kLNt1C4BogvHGUDRWFsNM+xTsJl1BNy0bzU2cIfyOjLx0h6Mz87A
u16oE9AdJwdsn+z8ZINqddYZCLrXTcUpWOT8zywhy4ggsASfURE2IRt9vh45Ewmm
s06RphxXR6/PYs3DvFx7qTkAtmjBD9fZlvnRqZia8qxa1kTjsOPzTS5Emhq6Toaw
knrWlMYwMwi+b79pvMBjeBVCTl+Yvdkn4WG6tfKizQIDAQABozEwLzAOBgNVHQ8B
Af8EBAMCAgQwHQYDVR0OBBYEFGZfWt6l0RiQGlXc0lR4J+OZSZJfMA0GCSqGSIb3
DQEBCwUAA4IBAQBxdOroYXF4bma2y3FWV8bi1b5RDIIgvUPZOrFz6KnKtb1X3LiO
BU8lUWNqHwigyBtde/3zBxc2JtUyhwgbA8A+Wm2k3fX1g93F/TLCw07uiaLMRgfz
/8Rqi14Zen3W4Jx65W69998h7R4dbWtPSx8T9WKChzjzgpQFZtH14EYmKu0Sv/Js
cehkERIym8bRpj903dcuNHdAqaufWudtz1YuM695knKyXsfYWH/mXX++1RZ4qVov
hBqoYvF7v89bOTYT9dmZnsTJtGvEXesxRJx+UTLBlshdFgH6hiH5wD0OHOna3MlA
Fjjx1IU0TkurRlYn2ZOmJYVhOMdGq+wTGWIX
EOF
  }
  # Adding TAG's to your Azure resources (Required)
  tags = {
    configuration = "terraform"
    system        = "S07373"
  }
}