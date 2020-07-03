variable "prefix" {
  description = "prefix for resources created"
  default     = "arch-hashi-f5-demo"
}

variable "uk_se_name" {
  description = "UK SE name tag"
  default     = "arch"
}

variable "f5_ami_search_name" { 
  description = "search term to find the appropriate F5 AMI for current region"
  default = "F5*BIGIP-14.1*Good*25Mbps*"
}

variable "username" { 
  description = "big-ip username"
  default = "admin"
}

variable "password" { 
  description = "big-ip password"
  default = "PasswordABC123!!"
}

variable "address" { 
  description = "big-ip address"
  default = "https://10.1.1.1"
}

variable "port" { 
  description = "name of preconfigured AWS secret, containing password"
  default = "8443"
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