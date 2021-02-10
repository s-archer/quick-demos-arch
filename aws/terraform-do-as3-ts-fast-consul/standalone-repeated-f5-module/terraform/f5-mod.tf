module bigip {
  count                       = var.instance_count
  source                      = "git::https://github.com/f5devcentral/terraform-aws-bigip-module.git"
  prefix                      = var.prefix
  ec2_key_name                = aws_key_pair.demo.key_name
  mgmt_subnet_ids             = [{ "subnet_id" = module.vpc.public_subnets[0], "public_ip" = true, "private_ip_primary" =  ""}]
  mgmt_securitygroup_ids      = [aws_security_group.f5.id]
  external_subnet_ids         = [{ "subnet_id" = module.vpc.public_subnets[0], "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = ""}]
  external_securitygroup_ids  = [aws_security_group.f5.id]
  internal_subnet_ids         = [{"subnet_id" =  module.vpc.private_subnets[0], "public_ip"=false, "private_ip_primary" = ""}]
  internal_securitygroup_ids  = [aws_security_group.f5_internal.id]
}