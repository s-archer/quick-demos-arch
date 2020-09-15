

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

# deploy base comfig using declaraitive onboarding

resource "bigip_do"  "do-f5-1" {
  do_json = templatefile("do.tmpl", {
    hostname    = jsonencode(var.hostname-f5-1),
    bigip1      = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_ip),
    bigip2      = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_2_int_ip),
    external_ip = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_1_ext_ip}/24"),
    internal_ip = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_ip}/24"),
    internal_gw = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_gw}/32"),
    peer_net    = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_2_int_cidr),
    admin_pass  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5_password),
    dns         = jsonencode("8.8.8.8"),
    ntp         = jsonencode("time.google.com")
  })
  provider = bigip.f5-1
  timeout = 5
}

resource "bigip_do"  "do-f5-2" {
  do_json = templatefile("do.tmpl", {
    hostname    = jsonencode(var.hostname-f5-2),
    bigip1      = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_ip),
    bigip2      = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_2_int_ip),
    external_ip = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_1_ext_ip}/24"),
    internal_ip = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-2_eth1_2_int_ip}/24"),
    internal_gw = jsonencode("${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_gw}/32"),
    peer_net    = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_2_int_cidr),
    admin_pass  = jsonencode(data.terraform_remote_state.aws_demo.outputs.f5_password),
    dns         = jsonencode("8.8.8.8"),
    ntp         = jsonencode("time.google.com")
  })
  provider = bigip.f5-2
  timeout = 5
}