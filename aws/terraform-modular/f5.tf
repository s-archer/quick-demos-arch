
module "arch_bigip" {
  # cidr will allocate a /24 cidr to each instance of BIG-IP (count), the module will carve this up into 8 x /27 subnets (32 addresses each)
  # The az element will will wrap using a standard mod algorithm, deploying BIG-IPs evenly across azs
  # total_vs_ip_count and max_ip_count_per_nic will automatically add enough NICs to fullfil the desired number of VS IPs.
  # 'max_ip_count_per_nic' includes, or counts, a self-ip.  So if there is a max of 20, one will be self-ip and 19 will be for VSs.
  source                  = "./arch_bigip_module"
  count                   = var.bigip_count
  total_vs_ip_count       = length(var.app_list)
  max_ip_count_per_nic    = 3
  region                  = var.region
  vpc_id                  = module.vpc.vpc_id
  az                      = element(local.azs, count.index)
  cidr                    = "10.0.${count.index}.0/24"
  igw_id                  = module.vpc.igw_id
  prefix                  = "${var.prefix}-${count.index}"
  security_group_mgmt     = aws_security_group.mgmt.id
  security_group_public   = aws_security_group.public.id
  security_group_private  = aws_security_group.private.id
  ssh_key_name            = aws_key_pair.demo.key_name
  iam_instance_profile    = aws_iam_instance_profile.as3.name
  f5_user                 = var.f5_user
  f5_ami_search_name      = var.f5_ami_search_name
  app_list                = var.app_list
}
