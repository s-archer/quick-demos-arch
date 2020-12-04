


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