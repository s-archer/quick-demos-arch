
output "f5_username" {
  value = "azureuser"
}

output "f5_password" {
  value = random_string.password.result
}

output "ui_f5-1" {
  value = "https://${azurerm_public_ip.mgmt_public_ip[0].ip_address}"
}
output "ui_f5-2" {
  value = "https://${azurerm_public_ip.mgmt_public_ip[1].ip_address}"
}

output "ssh_f5-1" {
  value = "ssh azureuser@${azurerm_public_ip.mgmt_public_ip[0].ip_address}"
}

output "ssh_f5-2" {
  value = "ssh azureuser@${azurerm_public_ip.mgmt_public_ip[1].ip_address}"
}

# output "f5_vs1" {
#   value = [aws_eip.external-vs1.private_ip, aws_eip.external-vs1.public_ip]
# }

output "f5_vs1_uri" {
  value = "http://${azurerm_public_ip.azurefw.ip_address}"
}


