data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}

variable f5cs_user     {}
variable f5cs_password {}


resource "null_resource" "eap-login" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -ksX POST https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions \
              -H "Content-Type: application/json" \
	            -u ${var.f5cs_user}:${var.f5cs_password} \
	            -d @"{ "username": "${var.f5cs_user}","password": "${var.f5cs_password}" }"
    EOF
  }
}
data "external" "example" {
  program = ["curl", "-ksX POST https://api.cloudservices.f5.com/v1/svc-subscription/subscriptions -H Content-Type: application/json -d { "username": "${var.f5cs_user}","password": "${var.f5cs_password}" }"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
  }
}

