
provider "bigip" {
  alias    = ""
  address  = "https://${aws_eip.f5-1.public_ip}:${var.port}"
  username = "${var.username}"
  password = "${random_string.password.result}"
}

# deploy application using as3
resource "bigip_as3" "nginx" {
  as3_json    = file("nginx.json")
  tenant_name = "consul_sd"
}
