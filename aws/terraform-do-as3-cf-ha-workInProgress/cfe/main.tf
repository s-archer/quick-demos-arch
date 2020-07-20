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
