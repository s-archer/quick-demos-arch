output "app_url" {
  value = "http://${data.terraform_remote_state.aws_demo.outputs.f5-1_eth1_1_ext_pub_ip_vs0}:80"
}
