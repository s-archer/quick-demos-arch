variable "prefix" {
  description = "prefix for resources created"
  default     = "arch-hashi-f5-demo"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "arch"
}

variable "instance_count" {
  description = "prefix for resources created"
  default     = "2"
}

variable "f5_ami_search_name" { 
  description = "search term to find the appropriate F5 AMI for current region"
  default = "F5*BIGIP-15.1*Good*25Mbps*"
}

variable "aws_secret_name" { 
  description = "name of secret created in aws secrets manage"
  default = "my_bigip_password"
}

variable "username" { 
  description = "big-ip username"
  default = "admin"
}

variable "password" { 
  description = "big-ip password"
  default = ""
}

variable "address" { 
  description = "big-ip address"
  default = ""
}

variable "port" { 
  description = "big-ip port, 443 default, use 8443 for single NIC"
  default = "443"
}

variable "libs_dir" {
  description = "Destination directory on the BIG-IP to download the A&O Toolchain RPMs"
  type        = string
  default     = "/config/cloud/aws/node_modules"
}

variable onboard_log {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  type        = string
  default     = "/var/log/startup-script.log"
}