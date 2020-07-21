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
      curl -k -X POST ${data.terraform_remote_state.aws_demo.outputs.f5-1_ui}/mgmt/shared/cloud-failover/declare \
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
      curl -k -X POST ${data.terraform_remote_state.aws_demo.outputs.f5-2_ui}/mgmt/shared/cloud-failover/declare \
              -H "Content-Type: application/json" \
	            -u ${data.terraform_remote_state.aws_demo.outputs.f5_username}:${data.terraform_remote_state.aws_demo.outputs.f5_password} \
	            -d @"cfe.json"
    EOF
  }
}


# provider "bigip" {
#   alias    = "f5-1"
#   address  = data.terraform_remote_state.aws_demo.outputs.f5-1_ui
#   username = data.terraform_remote_state.aws_demo.outputs.f5_username
#   password = data.terraform_remote_state.aws_demo.outputs.f5_password
# }

# provider "bigip" {
#   alias    = "f5-2"
#   address  = data.terraform_remote_state.aws_demo.outputs.f5-2_ui
#   username = data.terraform_remote_state.aws_demo.outputs.f5_username
#   password = data.terraform_remote_state.aws_demo.outputs.f5_password
# }

# resource "bigip_command" "f5-1-ha-state" {
#   provider = bigip.f5-1
#   commands   = ["show sys failover"]

#   depends_on = [ null_resource.f5-1-cfe, null_resource.f5-2-cfe ]

# }

# resource "bigip_command" "f5-2-ha-state" {
#   provider = bigip.f5-2
#   commands   = ["show sys failover"]

#   depends_on = [ null_resource.f5-1-cfe, null_resource.f5-2-cfe ]

# }

# resource "bigip_command" "f5-1-ha-force-standby" {
#   provider = bigip.f5-1
#   count = "${bigip_command.f5-1-ha-state} contains "active" ? 1 : 0"
  
#   commands   = ["run sys failover standby"]

# }

# resource "bigip_command" "f5-2-ha-force-standby" {
#   provider = bigip.f5-2
#   count = "${bigip_command.f5-2-ha-state} contains "active" ? 1 : 0"

#   commands   = ["run sys failover standby"]

# }