resource "aws_network_interface" "f5-1_eth0_mgmt" {
  subnet_id   = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.f5.id]
  private_ips = ["10.0.0.101"]

  tags = {
    Name = "mgmt_interface"
  }
}

resource "aws_eip" "f5-1_eth0_mgmt" {
  network_interface = aws_network_interface.f5-1_eth0_mgmt.id
  vpc               = true
}

resource "aws_network_interface" "f5-1_eth1_1_ext" {
  subnet_id   = module.vpc.public_subnets[1]
  security_groups = [aws_security_group.f5.id]
  private_ips = ["10.0.1.101"]

  tags = {
    Name = "external_interface"
  }
}

resource "aws_eip" "f5-1_eth1_1_ext" {
  network_interface = aws_network_interface.f5-1_eth1_1_ext.id
  vpc               = true
}

resource "aws_network_interface" "f5-1_eth1_2_int" {
  subnet_id   = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.f5_internal.id]
  private_ips = ["10.0.2.101"]

  tags = {
    Name = "internal_interface"
  }
}

data "template_file" "f5-1_init" {
  template = file("../scripts/f5_onboard.tmpl")

  vars = {
    password              = random_string.password.result
    internal_ip           = aws_network_interface.f5-1_eth1_2_int.private_ip
    internal_gw           = cidrhost(data.aws_subnet.f5-1_eth1_2_int.cidr_block, 1)
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

resource "aws_instance" "f5-1" {

  ami = data.aws_ami.f5_ami.id

  instance_type               = "m5.xlarge"
  user_data                   = data.template_file.f5-1_init.rendered
  key_name                    = aws_key_pair.demo.key_name
  iam_instance_profile        = "arch-cfe-route-role"
  root_block_device { delete_on_termination = true }

  network_interface {
    network_interface_id = aws_network_interface.f5-1_eth0_mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.f5-1_eth1_1_ext.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.f5-1_eth1_2_int.id
    device_index         = 2
  }

  provisioner "local-exec" {
    command = "while [[ \"$(curl -skiu ${var.username}:${random_string.password.result} https://${self.public_ip}:${var.port}/mgmt/shared/appsvcs/declare | grep -Eoh \"^HTTP/1.1 204\")\" != \"HTTP/1.1 204\" ]]; do sleep 5; done"
  }
  
  tags = {
    Name  = "${var.prefix}-f5"
    Env   = "consul"
    UK-SE = var.uk_se_name
  }
}
