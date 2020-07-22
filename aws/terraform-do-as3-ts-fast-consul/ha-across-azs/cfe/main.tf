data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}


resource "null_resource" "f5-1-cfe" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -ksX POST ${data.terraform_remote_state.aws_demo.outputs.f5-1_ui}/mgmt/shared/cloud-failover/declare \
              -H "Content-Type: application/json" \
	            -u ${data.terraform_remote_state.aws_demo.outputs.f5_username}:${data.terraform_remote_state.aws_demo.outputs.f5_password} \
	            -d @"cfe.json"
    EOF
  }
}


resource "null_resource" "f5-2-cfe" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -ksX POST ${data.terraform_remote_state.aws_demo.outputs.f5-2_ui}/mgmt/shared/cloud-failover/declare \
              -H "Content-Type: application/json" \
	            -u ${data.terraform_remote_state.aws_demo.outputs.f5_username}:${data.terraform_remote_state.aws_demo.outputs.f5_password} \
	            -d @"cfe.json"
    EOF
  }
}


provider "bigip" {
  alias    = "f5-1"
  address  = data.terraform_remote_state.aws_demo.outputs.f5-1_ui
  username = data.terraform_remote_state.aws_demo.outputs.f5_username
  password = data.terraform_remote_state.aws_demo.outputs.f5_password
}

provider "bigip" {
  alias    = "f5-2"
  address  = data.terraform_remote_state.aws_demo.outputs.f5-2_ui
  username = data.terraform_remote_state.aws_demo.outputs.f5_username
  password = data.terraform_remote_state.aws_demo.outputs.f5_password
}

resource "bigip_command" "f5-1-ha-state" {
  provider = bigip.f5-1
  commands   = ["show sys failover | grep -o active"]

  depends_on = [ null_resource.f5-1-cfe, null_resource.f5-2-cfe ]

}

resource "bigip_command" "f5-2-ha-state" {
  provider = bigip.f5-2
  commands   = ["show sys failover | grep -o active"]

  depends_on = [ null_resource.f5-1-cfe, null_resource.f5-2-cfe ]

}

# The following block is the recommended way to conditionally (see the '?') perform a command.  
# If count is zero, nothing happens.  If it's greater than zero, the command is executed.
# The regexall part of the command is the recommended way to searchg for a string ("active") in 
# a string (failover status result e.g. "active" or "standby")
resource "bigip_command" "f5-1-ha-force-standby" {
  depends_on = [bigip_command.f5-1-ha-state]
  provider = bigip.f5-1
  #count = length(regexall("active", bigip_command.f5-1-ha-state.command_result[0])) > 0 ? 1 : 0
  
  commands   = ["run sys failover standby"]

}

resource "bigip_command" "f5-2-ha-force-standby" {
  depends_on = [bigip_command.f5-2-ha-state]
  provider = bigip.f5-2
  #count = length(regexall("active", bigip_command.f5-2-ha-state.command_result[0])) > 0 ? 1 : 0
  
  commands   = ["run sys failover standby"]
  
}

output "state" {
  value = "STATE: ${bigip_command.f5-1-ha-state.command_result[0]}"
}

output "bigip1-ui" {
  value = "BIGIP1: ${data.terraform_remote_state.aws_demo.outputs.f5-1_ui}"
}

output "bigip2-ui" {
  value = "BIGIP2: ${data.terraform_remote_state.aws_demo.outputs.f5-2_ui}"
}

output "bigip-pass" {
  value = "PASS: ${data.terraform_remote_state.aws_demo.outputs.f5_password}"
}

output "nginx_app_url" {
  value = "NGINX_APP: http://${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_1_ext_pub_ip_vs0}"
}

output "consul_ui" {
  value = "CONSUL_UI: ${data.terraform_remote_state.aws_demo.outputs.consul_ui}"
}