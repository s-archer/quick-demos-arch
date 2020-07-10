# resource "aws_network_interface" "f5-1_eth1_1_ext" {
#   subnet_id   = module.vpc.public_subnets[1]
#   security_groups = [aws_security_group.f5.id]
#   private_ips = ["10.0.1.101"]
#   tags = {
#     Name = "external_interface"
#   }
# }

# resource "aws_eip" "f5-1_eth1_1_ext" {
#   network_interface = aws_network_interface.f5-1_eth1_1_ext.id
#   vpc               = true
# }

# resource "aws_network_interface" "f5-2_eth1_1_ext" {
#   subnet_id   = module.vpc.public_subnets[3]
#   security_groups = [aws_security_group.f5.id]
#   private_ips = ["10.0.11.102"]

#   tags = {
#     Name = "external_interface"
#   }
# }

# resource "aws_eip" "f5-2_eth1_1_ext" {
#   network_interface = aws_network_interface.f5-2_eth1_1_ext.id
#   vpc               = true
# }

# variable "username" { 
#   description = "big-ip username"
#   default = "admin"
# }

