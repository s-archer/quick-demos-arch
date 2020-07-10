terraform {
  required_providers {
    bigip = "= 1.2"
  }
}
data "terraform_remote_state" "aws_demo" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
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

# deploy application using as3
resource "bigip_as3" "arch-f5-1" {
  as3_json    = file("arch.json")
  provider = bigip.f5-1
  tenant_filter = "arch"
}
resource "bigip_as3" "arch-f5-2" {
  as3_json    = file("arch.json")
  provider = bigip.f5-2
  tenant_filter = "arch"
}