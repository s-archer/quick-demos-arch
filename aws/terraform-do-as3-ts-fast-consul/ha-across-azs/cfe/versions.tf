terraform {
  required_providers {
    bigip = {
      source = "f5networks/bigip"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
