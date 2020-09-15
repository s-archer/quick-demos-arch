# terraform {
#   required_providers {
#     bigip = {
#       source = "github.com/F5Networks/bigip"
#     }
#   }
#   required_version = ">= 0.13"
# }
terraform {
  required_providers {
    bigip = {
      source = "terraform-providers/bigip"
    }
  }
  required_version = ">= 0.13"
}
