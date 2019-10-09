terraform {
  required_version = "<= 0.11.14"
}

provider "aws" {
  region = "${terraform.workspace}"
}
