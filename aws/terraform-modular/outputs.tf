
output "o01_mgmt_cidrs" {
  value = module.arch_bigip[*].mgmt_cidrs
}

output "o02_pub_cidrs" {
  value = module.arch_bigip[*].pub_cidrs
}

output "o03_priv_cidrs" {
  value = module.arch_bigip[*].priv_cidrs
}

output "o04_all_pub_cidrs" {
  value = module.arch_bigip[*].all_pub_cidrs
}

output "o11_mgmt_ips" {
  value = module.arch_bigip[*].mgmt_ips
}

output "o12_mgmt_pub_ips" {
  value = module.arch_bigip[*].mgmt_pub_ips.public_ip
}

output "o13_pub_ips" {
  value = module.arch_bigip[*].pub_ips
}

output "o14_pub_self_ips_list" {
  value = module.arch_bigip[*].pub_self_ips_list
}

output "o15_pub_vs_ips_list" {
  value = module.arch_bigip[*].pub_vs_ips_list
}

output "o16_priv_ips" {
  value = module.arch_bigip[*].priv_ips
}

output "o17_pub_vs_eips_list" {
  value = module.arch_bigip[*].pub_vs_eips_list
}

output "o21_mgmt_subnet_ids" {
  value = module.arch_bigip[*].mgmt_subnet_ids
}

output "o22_pub_subnet_ids" {
  value = module.arch_bigip[*].pub_subnet_ids
}

output "o23_priv_subnet_ids" {
  value = module.arch_bigip[*].priv_subnet_ids
}

output "o24_pub_and_mgmt_subnet_ids" {
  value = module.arch_bigip[*].pub_and_mgmt_subnet_ids
}

output "o31_f5_password" {
  value = module.arch_bigip[*].f5_password
}

output "o32_f5_ssh" {
  value = [ 
    for index, each_ip in module.arch_bigip[*].mgmt_pub_ips.public_ip : 
      format("ssh admin@%s -i ssh-key.pem password: %s", each_ip, module.arch_bigip[index].f5_password)
  ]
}

output "o33_f5_ui" {
  value = [ 
    for index, each_ip in module.arch_bigip[*].mgmt_pub_ips.public_ip : 
      format("https://%s/ password: %s", each_ip, module.arch_bigip[index].f5_password)
  ]
}

output "o34_app0_links" {
  value = [ for each_app in var.app_list :
    format("Name: %s , URL: https://%s.%s/", each_app[0], each_app[0], each_app[1]) 
  ]
}
# output "o50_debug_app_list" {
#   value = module.arch_bigip[*].app_list
# }