variable "region" {
  description = "AWS region name"
  default     = "eu-west-2"
}
variable "azs_short" {
  description = "Assumes three AZs within region.  Locals below will format the full AZ names based on Region"
  default     = ["a", "b", "c"]
}
variable "cidr" {
  description = "cidr used for AWS VPC"
  default     = "10.0.0.0/16"
}
variable "bigip_count" {
  description = "number of BIG-IP instances to deploy"
  default     = "2"
}
variable "f5_ami_search_name" {
  description = "filter used to find AMI for deployment"
  default     = "F5*BIGIP-15.1.1*Best*25Mbps*"
}
variable "f5_user" {
  description = "supplied by module parent"
  default     = "admin"
}
variable "prefix" {
  description = "prefix used for naming objects created in AWS"
  default     = "arch-tf-modular"
}
variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "arch"
}
locals {
  azs = [
    for each_az in var.azs_short : format("%s%s", var.region, each_az)
  ]
}
variable "f5cs_gslb_zone" {
  description = "F5 Cloud Services Zone"
  default     = "gslb.archf5.com"
}

variable "f5cs_user" {
  description = "F5 Cloud Services Login"
  default     = ""
}
variable "f5cs_pass" {}