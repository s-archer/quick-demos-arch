provider azurerm {
  version = "~>2.0"
  features {}
  subscription_id = var.subscription_id
  client_secret   = var.client_secret
  client_id       = var.client_id
  tenant_id       = var.tenant_id
}

data "http" "myip" {
  url = "http://ipv4bot.whatismyipaddress.com"
}

resource "random_string" "password" {
  length      = 10
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

