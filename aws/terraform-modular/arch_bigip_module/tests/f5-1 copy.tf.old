provider "aws" {
  region = "eu-west-2"
  # region = "eu-central-1"
}

# Load some json variables from a file (https://discuss.hashicorp.com/t/how-to-work-with-json/2345)
locals {
  json_vars = jsondecode(file("${path.module}/variables.json"))
}

locals {
  cidr = local.json_vars.cidr
}

locals {
  mgmt_cidrs = [cidrsubnet(local.cidr, 8, 0)]
}

locals {
  tmm_cidr_qty = min((local.json_vars.public_subnets.total_ip_count / local.json_vars.public_subnets.max_ip_count_per_subnet), 20)
}

locals {
  tmm_cidrs = [
      for i in range(local.tmm_cidr_qty) : cidrsubnet(local.cidr, 8, (i + 1))
  ]
}

locals {
  all_pub_cidrs = [
      for i in range(local.tmm_cidr_qty + 1) : cidrsubnet(local.cidr, 8, (i))
  ]
}

locals {
  mgmt_ips = {
      for each_cidr in local.mgmt_cidrs :
        each_cidr => [ for i in range(1) : 
          cidrhost(each_cidr, (i + 1))
        ]
  }
}

locals {
  tmm_ips = {
      for each_cidr in local.tmm_cidrs :
        each_cidr => [ for i in range(min (local.json_vars.public_subnets.max_ip_count_per_subnet, local.json_vars.public_subnets.total_ip_count)) : 
          cidrhost(each_cidr, (i + 9))
        ]
  }
}
# Test to show how chunking works.  Allows us to allocate specific number of IPs, when an ENI has a maximum (e.g. max 20).  Setting 32 IPs would create 
# one chunk of 20 and one chunk of 12.  Each chunk gets a dedicated ENI and CIDR. 
locals {
  test_chunks = [
    for each_chunk in chunklist(range(1, (local.json_vars.public_subnets.total_ip_count+1)), local.json_vars.public_subnets.max_ip_count_per_subnet) :
      format("Chunk Length = %d, Values = %v, Chunk Index = %d, Chunk CIDR = %s", length(each_chunk), each_chunk, (each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet, cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet))))
      ]
}

# Just print out the tmm CIDRs
# locals {
#   test = [
#     for each_chunk in chunklist(range(1, (local.json_vars.public_subnets.total_ip_count+1)), local.json_vars.public_subnets.max_ip_count_per_subnet) :
#       cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet)+1))
#       ]
# }

locals {
  test = {
    for each_chunk in chunklist(range(1, (local.json_vars.public_subnets.total_ip_count+1)), local.json_vars.public_subnets.max_ip_count_per_subnet) :
      cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet))) => [ for i in range(length(each_chunk)) : 
          cidrhost(cidrsubnet(local.cidr, 8,(((each_chunk[0] + (local.json_vars.public_subnets.max_ip_count_per_subnet - 1)) / local.json_vars.public_subnets.max_ip_count_per_subnet))), (i + 9))
      ]
      }
}

locals {
  pub_ips_list = flatten([
    for each_subnet in local.tmm_ips : 
      each_subnet
  ])
}


# output "test_elements" {
#   value = local.test[local.tmm_cidrs[0]]
# } 

# output "test" {
#   value = local.test
# } 
# output "test_chunks" {
#   value = local.test_chunks
# } 
output "mgmt_cidrs" {
  value = local.mgmt_cidrs
} 

output "tmm_cidrs" {
  value = local.tmm_cidrs[0]
} 

output "pub_ips_list" {
  value = local.pub_ips_list
} 

# output "mgmt_ips" {
#   value = local.mgmt_ips
# } 

# output "mgmt_ips_list" {
#   value = local.mgmt_ips[local.mgmt_cidrs[0]]
# } 

# output "tmm_ips" {
#   value = local.tmm_ips
# } 