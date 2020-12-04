

#
# Create a random id
#
resource random_id id {
  byte_length = 2
}

resource random_string storage {
  length      = 4
  upper       = false
  lower       = true
  number      = false
  special     = false
}
#
# Create a resource group
#
resource azurerm_resource_group rg {
  name     = format("%s-rg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

module "network" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = format("%s-vnet-%s", var.prefix, random_id.id.hex)
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.cidr]
  subnet_prefixes     = [cidrsubnet(var.cidr, 8, 1), cidrsubnet(var.cidr, 8, 2), cidrsubnet(var.cidr, 8, 3), cidrsubnet(var.cidr, 8, 4)]
  subnet_names        = ["mgmt", "external", "internal", "AzureFirewallSubnet"]

  tags = {
    environment = "dev"
    costcenter  = "it"
  }
}

data "azurerm_subnet" "mgmt" {
  name                 = "mgmt"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

data "azurerm_subnet" "external" {
  name                 = "external"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

data "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

data "azurerm_subnet" "AzureFirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  virtual_network_name = module.network.vnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  depends_on           = [module.network]
}

resource "azurerm_route_table" "azurefw" {
  name                          = "${var.prefix}-ext-route-alien"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = {
    f5_cloud_failover_label = "mydeployment"
    f5_self_ips             = "${azurerm_network_interface.ext_nic[0].private_ip_address},${azurerm_network_interface.ext_nic[1].private_ip_address}"
    environment             = "Production"
  }
}

resource "azurerm_route" "ext_route_alien" {
  name                   = "alien"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.azurefw.name
  address_prefix         = var.alien_prefix
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.ext_nic[0].private_ip_addresses[0]
}

resource "azurerm_subnet_route_table_association" "azurefw-alien" {
  subnet_id      = data.azurerm_subnet.AzureFirewallSubnet.id
  route_table_id = azurerm_route_table.azurefw.id
}

resource "azurerm_subnet_route_table_association" "azurefw-external" {
  subnet_id      = data.azurerm_subnet.external.id
  route_table_id = azurerm_route_table.azurefw.id
}

resource "azurerm_storage_account" "cfestorage" {
  name                     = "cfestorage${random_string.storage.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    f5_cloud_failover_label = "staging"
  }
}