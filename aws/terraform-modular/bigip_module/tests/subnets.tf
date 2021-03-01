# This file automatically generates subnets and IPs based on the values provided in the variables.json file, for example:
#
# "public_subnets": {
#     "ip_count": 200,
#     "ip_count_per_subnet": 20
#
variable "total_vs_ip_count" {
  description = "supplied by module parent"
  default     = "21"
}

variable "max_ip_count_per_nic" {
  description = "supplied by module parent"
  default     = "20"
}


locals {
  json_vars = jsondecode(file("variables.json"))
}

locals {
  # Get the VPC CIDR.
  cidr = "10.0.1.0/24"

  #    ***** MGMT *****
  #
  # Auto generate the public MGMT subnet from the CIDR.
  mgmt_cidrs = [cidrsubnet(local.cidr, 3, 0)]

  # Auto generate the mgmt IP (.4) using the mgmt subnet.
  mgmt_ips = {
    for each_cidr in local.mgmt_cidrs :
    each_cidr => [for i in range(1) :
      cidrhost(each_cidr, (i + 4))
    ]
  }

  #    ***** PRIVATE *****
  #
  # Auto generate the private subnet from the CIDR.
  priv_cidrs = [cidrsubnet(local.cidr, 3, 7)]

  # Create a simple list of just the 'tmm' SELF IPs.  Need this list to loop through, in order to define self-ips.
  priv_ips = [
    for each_cidr in local.priv_cidrs : format("%s/%s", cidrhost(each_cidr, 4), element(split("/", each_cidr), 1))
  ]

  # # Auto generate the private self-IP (.4) using the private subnet.
  # priv_ips = {
  #   for each_cidr in local.priv_cidrs :
  #   each_cidr => [for i in range(1) :
  #     cidrhost(each_cidr, (i + 4))
  #   ]
  # }
  #    ***** PUBLIC *****
  #
  # Determine how many public 'tmm' subnets are required. For example, you might set the max_ip_count_per_subnet to 20, because that is
  # the maximum number of IPs an EC2 instance can support on a single interface.  Therefore if you need 25 public IPs, we would need two
  # public subnets, the first could accommodate 20 IPs and the second could accommodate the remaining 5 IPs.
  pub_cidr_qty = min((var.total_vs_ip_count / (var.max_ip_count_per_nic -1)), 20)

  # Auto generate a list containing the correct quantity of public 'tmm' subnets.   
  pub_cidrs = [
    for i in range(local.pub_cidr_qty) : cidrsubnet(local.cidr, 3, (i + 1))
  ]

  # Auto generate a list of all public ('mgmt' and 'tmm') subnets.
  all_pub_cidrs = [
    for i in range(local.pub_cidr_qty + 1) : cidrsubnet(local.cidr, 3, (i))
  ]

  # Auto generate the correct quantity of public 'tmm' IPs, using as many subnets as necessary. Creates a map of subnets, each containing a list of IPs.
  # pub_ips = {
  #   for each_chunk in chunklist(range(1, (var.total_vs_ip_count + 1)), (var.max_ip_count_per_nic)) :
  #   cidrsubnet(local.cidr, 3, (((each_chunk[0] + (var.max_ip_count_per_nic - 1)) / var.max_ip_count_per_nic + 1))) => [for i in range(length(each_chunk)) :
  #     cidrhost(cidrsubnet(local.cidr, 3, (((each_chunk[0] + (var.max_ip_count_per_nic - 1)) / var.max_ip_count_per_nic))), (i + 4))
  #   ]
  # }  

  pub_ips = {
    for index, each_cidr in local.pub_cidrs :  
      each_cidr => [for i in range(1, (var.max_ip_count_per_nic +1)) :
        cidrhost(each_cidr, i + 3) if ((index * var.max_ip_count_per_nic) + i) <= (var.total_vs_ip_count + length(local.pub_cidrs) )
      ]
  }


}

output "mgmt_cidrs" {
  value = local.mgmt_cidrs
}

output "pub_cidrs" {
  value = local.pub_cidrs
}

# output "priv_cidrs" {
#   value = local.priv_cidrs
# }

output "all_pub_cidrs" {
  value = local.all_pub_cidrs
}

output "mgmt_ips" {
  value = local.mgmt_ips
}


output "pub_ips" {
  value = local.pub_ips
}

# output "priv_ips" {
#   value = local.priv_ips
# }

output "pub_cidr_qty" {
  value = local.pub_cidr_qty
}

output "z_pub_ips_list" {
  value = local.pub_ips_list
}
output "z_pub_self_ips_list" {
  value = local.pub_self_ips_list
}
output "z_pub_vs_ips_list" {
  value = local.pub_vs_ips_list
}

locals {

  pub_ips_list = flatten([
    for each_subnet in local.pub_ips :
    each_subnet
  ])

  pub_self_ips_list = [
     for each_cidr in local.pub_cidrs : format("%s/%s", cidrhost(each_cidr, 4), element(split("/", each_cidr), 1))
  ]

  pub_vs_ips_list = [
    for index, each_cidr in local.pub_ips : 
      [ for each_ip in each_cidr : 
        format("%s/%s", each_ip, element(split("/", index), 1)) if each_ip != cidrhost(index, 4)
      ]
  ]
  
}