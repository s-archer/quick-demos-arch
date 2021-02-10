terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
  # region = "eu-central-1"
}
