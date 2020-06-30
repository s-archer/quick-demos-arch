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
resource "bigip_as3" "arch-1" {
  as3_json    = file("arch.json")
  tenant_filter = "arch"
}
resource "bigip_as3" "arch-2" {
  as3_json    = file("arch.json")
  tenant_filter = "arch"
}

# f5-1_ip = 3.11.75.231
# f5-1_ssh = ssh admin@3.11.75.231 -i terraform-20200630074504350900000001.pem
# f5-1_ui = https://3.11.75.231:8443
# f5-2_ip = 18.133.34.245
# f5-2_ssh = ssh admin@18.133.34.245 -i terraform-20200630074504350900000001.pem
# f5-2_ui = https://18.133.34.245:8443
# f5_password = B8bz42XlJm
# f5_username = admin