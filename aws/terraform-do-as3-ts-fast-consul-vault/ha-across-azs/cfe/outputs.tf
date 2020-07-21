output "app_url" {
  value = "http://${data.terraform_remote_state.aws_demo.outputs.f5-1_eth0_mgmt_pub_ip}:80"
}
