terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  #shared_credentials_file = "~/.aws/credentials"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
  region                   = var.region
}
