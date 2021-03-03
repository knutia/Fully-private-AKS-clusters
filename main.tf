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
  subnet_prefixes         = ["10.0.0.0/24", "10.0.1.0/24"]
  subnet_names            = ["AzureFirewallSubnet", "jumpbox-subnet"]
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
  depends_on = [module.networks_rg, module.hub_vnet, module.kube_vnet]
}

resource "azurerm_virtual_network_peering" "example-2" {
  name                      = "Spoke1ToHub"
  resource_group_name       = module.networks_rg.resource_name
  virtual_network_name      = module.kube_vnet.vnet_name
  remote_virtual_network_id = module.hub_vnet.vnet_id
  depends_on = [module.networks_rg, module.hub_vnet, module.kube_vnet]
}

resource "azurerm_public_ip" "example" {
  name                = "dzpraks1"
  location            = module.networks_rg.location
  resource_group_name = module.networks_rg.resource_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "example" {
  name                = "dzpraks1"
  location            = module.networks_rg.location
  resource_group_name = module.networks_rg.resource_name

  ip_configuration {
    name                 = "dzpraks1"
    #subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }
}