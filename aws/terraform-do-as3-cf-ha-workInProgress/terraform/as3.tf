# # terraform {
# #   required_providers {
# #     bigip = "= 1.2"
# #   }
# # }

# provider "bigip" {
#   alias    = "f5-1"
#   address  = "https://${aws_instance.f5-1.public_ip}:${var.port}"
#   username = var.username
#   password = random_string.password.result
# }

# provider "bigip" {
#   alias    = "f5-2"
#   address  = "https://${aws_instance.f5-2.public_ip}:${var.port}"
#   username = var.username
#   password = random_string.password.result
# }

# # deploy application using as3
# resource "bigip_as3" "arch-1" {
#   as3_json    = file("arch.json")
#   provider = bigip.f5-1
#   tenant_filter = "arch"
# }
# resource "bigip_as3" "arch-2" {
#   as3_json    = file("arch.json")
#   provider = bigip.f5-2
#   tenant_filter = "arch"
# }