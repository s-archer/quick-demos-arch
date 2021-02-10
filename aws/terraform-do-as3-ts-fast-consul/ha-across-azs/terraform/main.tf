terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "Default"
}
