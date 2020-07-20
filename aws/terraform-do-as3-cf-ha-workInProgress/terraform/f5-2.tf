# MGMT INTERFACE ---------------
resource "aws_network_interface" "f5-2_eth0_mgmt" {
  subnet_id   = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.f5.id]
  private_ips = ["10.0.10.102"]

  tags = {
    Name = "mgmt_interface"
  }
}

resource "aws_eip" "f5-2_eth0_mgmt" {
  network_interface         = aws_network_interface.f5-2_eth0_mgmt.id
  associate_with_private_ip = "10.0.10.102"
  vpc                       = true

  tags                      = {
    Name                    = "${var.prefix}-2-mgmt"
  }
}

# EXT INTERFACE ----------------

variable "f5-2_eth1_1_ext_ips" {
  description = "Self IP Plus secondary IPs for VIPS"
  type        = list
  default     = ["10.0.11.102","10.0.11.200","10.0.11.201"]
}

resource "aws_network_interface" "f5-2_eth1_1_ext" {
  subnet_id   = module.vpc.public_subnets[3]
  security_groups = [aws_security_group.f5.id]
  # private_ips = ["10.0.11.102"]
  private_ips = var.f5-2_eth1_1_ext_ips

  tags = {
    Name                      = "external_interface"
    f5_cloud_failover_nic_map = "eth1_1_ext"
  }
}

resource "aws_eip" "f5-2_eth1_1_ext_self" {
  network_interface         = aws_network_interface.f5-2_eth1_1_ext.id
  associate_with_private_ip = "10.0.11.102"
  vpc                       = true

  tags                      = {
    Name                    = "${var.prefix}-2-ext-self"
  }
}

# Just allocated EIPs to F5-1 because CFE will move them on failover
#
# resource "aws_eip" "f5-2_eth1_1_ext_vs0" {
#   network_interface = aws_network_interface.f5-2_eth1_1_ext.id
#   associate_with_private_ip = "10.0.11.200"
#   vpc               = true
# }

# resource "aws_eip" "f5-2_eth1_1_ext_vs1" {
#   network_interface = aws_network_interface.f5-2_eth1_1_ext.id
#   associate_with_private_ip = "10.0.11.201"
#   vpc               = true
# }

# INT INTERFACE ----------------

resource "aws_network_interface" "f5-2_eth1_2_int" {
  subnet_id   = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.f5_internal.id]
  private_ips = ["10.0.12.102"]

  tags = {
    Name = "internal_interface"
  }
}

# ONBOARDING TEMPLATE  ---------

data "template_file" "f5-2_init" {
  template = file("../scripts/f5_onboard.tmpl")

  vars = {
    password              = random_string.password.result
    internal_ip           = aws_network_interface.f5-2_eth1_2_int.private_ip
    internal_gw           = cidrhost(data.aws_subnet.f5-2_eth1_2_int.cidr_block, 1)
    doVersion             = "latest"
    #example version:
    #as3Version           = "3.16.0"
    as3Version            = "latest"
    tsVersion             = "latest"
    cfVersion             = "latest"
    fastVersion           = "latest"
    libs_dir              = var.libs_dir
    onboard_log           = var.onboard_log
    projectPrefix         = var.prefix
  }
}

# AMI INSTANCE ----------------

resource "aws_instance" "f5-2" {

  ami = data.aws_ami.f5_ami.id

  instance_type               = "m5.xlarge"
  user_data                   = data.template_file.f5-2_init.rendered
  key_name                    = aws_key_pair.demo.key_name
  #iam_instance_profile        = "arch-cfe-route-role"
  iam_instance_profile        = aws_iam_instance_profile.cfe.name
  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.f5-2_eth0_mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.f5-2_eth1_1_ext.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.f5-2_eth1_2_int.id
    device_index         = 2
  }

  provisioner "local-exec" {
    command = "while [[ \"$(curl -skiu ${var.username}:${random_string.password.result} https://${self.public_ip}:${var.port}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 204\")\" != \"HTTP/1.1 204\" ]]; do sleep 5; done"
  }
  
  tags = {
    Name = "${var.prefix}-f5-2"
    Env  = "consul"
  }

}
