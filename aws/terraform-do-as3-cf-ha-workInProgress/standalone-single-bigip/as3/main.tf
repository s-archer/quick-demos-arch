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

# provider "bigip" {
#   alias    = "f5-2"
#   address  = data.terraform_remote_state.aws_demo.outputs.f5-2_ui
#   username = data.terraform_remote_state.aws_demo.outputs.f5_username
#   password = data.terraform_remote_state.aws_demo.outputs.f5_password
# }

# deploy application using as3
resource "bigip_as3" "arch-f5-1" {
  as3_json    = templatefile("nginx.tmpl", {
    virtual_ip_1  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_1_ext_ip_vs0)
    virtual_ip_2  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_1_ext_ip_vs0)
    tenant_name = jsonencode("arch")
    app_name    = jsonencode("nginx")
  })
  provider = bigip.f5-1
  tenant_filter = "arch"
}


# resource "bigip_as3" "arch-f5-2" {
#   as3_json    = templatefile("nginx.tmpl", {
#     virtual_ip_1  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_1_ext_ip_vs0)
#     virtual_ip_2  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_1_ext_ip_vs0)
#     tenant_name = jsonencode("arch")
#     app_name    = jsonencode("nginx")
#   })
#   provider = bigip.f5-2
#   tenant_filter = "arch"
# }

# For testing, writes out to file.
#
# resource "local_file" "test_json" {
#     content     = templatefile("nginx.tmpl", {
#       virtual_ip  = jsonencode("10.1.99.100")
#       tenant_name = jsonencode("arch")
#       app_name    = jsonencode("nginx")
#       })
#     filename = "${path.module}/test.json"
# }