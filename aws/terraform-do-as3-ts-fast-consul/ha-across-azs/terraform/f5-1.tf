# MGMT INTERFACE ---------------
resource "aws_network_interface" "f5-1_eth0_mgmt" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.f5.id]
  private_ips     = ["10.0.0.101"]

  tags = {
    Name = "mgmt_interface"
  }
}

resource "aws_eip" "f5-1_eth0_mgmt" {
  network_interface         = aws_network_interface.f5-1_eth0_mgmt.id
  associate_with_private_ip = "10.0.0.101"


  tags = {
    Name = "${var.prefix}-1-mgmt"
  }
}

# EXT INTERFACE ----------------

variable "f5-1_eth1_1_ext_ips" {
  description = "Self IP Plus secondary IPs for VIPS"
  type        = list(any)
  default     = ["10.0.1.101", "10.0.1.200", "10.0.1.201"]
}

resource "aws_network_interface" "f5-1_eth1_1_ext" {
  subnet_id       = module.vpc.public_subnets[2]
  security_groups = [aws_security_group.f5.id]
  #private_ips = ["10.0.1.101"]
  private_ips = var.f5-1_eth1_1_ext_ips

  tags = {
    Name                      = "external_interface"
    f5_cloud_failover_nic_map = "eth1_1_ext"
  }
}

resource "aws_eip" "f5-1_eth1_1_ext_self" {
  network_interface         = aws_network_interface.f5-1_eth1_1_ext.id
  associate_with_private_ip = "10.0.1.101"


  tags = {
    Name = "${var.prefix}-1-ext-self"
  }
}

resource "aws_eip" "f5-1_eth1_1_ext_vs0" {
  network_interface         = aws_network_interface.f5-1_eth1_1_ext.id
  associate_with_private_ip = "10.0.1.200"


  tags = {
    Name                    = "${var.prefix}-ext-vs0"
    f5_cloud_failover_label = "mydeployment"
    # In multi-az you need to specify both VIPs that might map to the EIP.
    f5_cloud_failover_vips = "10.0.1.200,10.0.11.200"
  }

}

# Commenting out to restrict to single vs for now
# resource "aws_eip" "f5-1_eth1_1_ext_vs1" {
#   network_interface         = aws_network_interface.f5-1_eth1_1_ext.id
#   associate_with_private_ip = "10.0.1.201"
#   

#   tags                      = {
#     Name                    = "${var.prefix}-ext-vs1"
#     f5_cloud_failover_label = "mydeployment"
#     # In multi-az you need to specify both VIPs that might map to the EIP.
#     f5_cloud_failover_vips  = "10.0.1.201,10.0.11.201"
#   }

# }

# INT INTERFACE ----------------

resource "aws_network_interface" "f5-1_eth1_2_int" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.f5_internal.id]
  private_ips     = ["10.0.2.101"]

  tags = {
    Name = "internal_interface"
  }
}

# AMI INSTANCE ----------------

resource "aws_instance" "f5-1" {

  ami = data.aws_ami.f5_ami.id

  instance_type = "m5.xlarge"
  user_data = templatefile("./templates/user-data-bip-1.tpl", {
    password        = random_string.password.result
    internal_ip     = aws_network_interface.f5-1_eth1_2_int.private_ip
    internal_gw     = cidrhost(data.aws_subnet.f5-1_eth1_2_int.cidr_block, 1)
    doVersion       = "latest"
    as3Version      = "latest"
    tsVersion       = "latest"
    cfVersion       = "latest"
    fastVersion     = "latest"
    libs_dir        = var.libs_dir
    onboard_log     = var.onboard_log
    projectPrefix   = var.prefix
    # For DO
    hostname        = jsonencode(var.hostname-f5-1),
    bigip1          = jsonencode(aws_network_interface.f5-1_eth1_2_int.private_ip),
    bigip2          = jsonencode(aws_network_interface.f5-2_eth1_2_int.private_ip),
    external_ip     = jsonencode("${var.f5-1_eth1_1_ext_ips[0]}/24"),
    internal_ip     = jsonencode("${aws_network_interface.f5-1_eth1_2_int.private_ip}/24"),
    internal_ip_raw = "${aws_network_interface.f5-1_eth1_2_int.private_ip}/24",
    internal_gw     = jsonencode("${cidrhost(data.aws_subnet.f5-1_eth1_2_int.cidr_block, 1)}/32"),
    internal_gw_raw = cidrhost(data.aws_subnet.f5-1_eth1_2_int.cidr_block, 1),
    peer_net        = jsonencode(data.aws_subnet.f5-2_eth1_2_int.cidr_block),
    admin_pass      = jsonencode(random_string.password.result),
    dns             = jsonencode("8.8.8.8"),
    ntp             = jsonencode("time.google.com")
    # For AS3
    virtual_ip_1    = jsonencode(var.f5-1_eth1_1_ext_ips[1])
    virtual_ip_2    = jsonencode(var.f5-2_eth1_1_ext_ips[1])
    tenant_name     = jsonencode("arch")
    app_name        = jsonencode("nginx")
  })
  key_name = aws_key_pair.demo.key_name
  #iam_instance_profile        = "arch-cfe-route-role"
  iam_instance_profile = aws_iam_instance_profile.cfe.name
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
    Name  = "${var.prefix}-f5-1"
    Env   = "consul"
    UK-SE = var.uk_se_name
  }
}
