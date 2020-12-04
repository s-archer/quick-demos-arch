provider "aws" {
  region = "eu-west-2"
}

module "arch_bigip" {
  source = "./arch_bigip_module"
  count  = 2
#   cidr   = "10.${count.index}.0.0/16"

}

# Load some json variables from a file (https://discuss.hashicorp.com/t/how-to-work-with-json/2345)
