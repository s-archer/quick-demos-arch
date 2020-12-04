resource "azurerm_public_ip" "azurefw" {
  name                = "azurefwpip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azurefwudr" {
  name                = "azurefwudr"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "AzureFirewallSubnet"
    subnet_id            = data.azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.azurefw.id
  }
}

resource "azurerm_firewall_nat_rule_collection" "natudr01" {
  name                = "natudr01"
  azure_firewall_name = azurerm_firewall.azurefwudr.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "udr01" 

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "80",
    ]

    destination_addresses = [
      azurerm_public_ip.azurefw.ip_address
    ]

    translated_port = 80

    translated_address = "10.99.0.1"

    protocols = [
      "TCP"
    ]
  }
}