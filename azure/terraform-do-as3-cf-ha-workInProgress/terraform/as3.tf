
 provider "bigip" {
   address  = "https://${aws_eip.f5-1.public_ip}:${var.port}"
   username = var.username
   password = random_string.password.result
   alias    = "azure1"
 }

 provider "bigip" {
   address  = "https://${aws_eip.f5-2.public_ip}:${var.port}"
   username = var.username
   password = random_string.password.result
   alias    = "azure2"
 }

 resource "bigip_as3" "as3_azure1" {
  as3_json    = file("./as3-declaration.json")
  provider    = bigip.azure1
  tenant_filter = "arch"
}

 resource "bigip_as3" "as3_azure2" {
  as3_json    = file("./as3-declaration.json")
  provider    = bigip.azure2
  tenant_filter = "arch"
}