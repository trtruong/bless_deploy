terraform {
  backend "s3" {
    encrypt              = "true"
    bucket               = "use2-cops-tfstates"
    dynamodb_table       = "use2-cops-terraform-remote-state"
    region               = "us-east-2"
    key                  = "prod/bless/bless-lambda/terraform.tfstate"
    workspace_key_prefix = "regions"
  }
}

data "terraform_remote_state" "bless-kms" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config = {
    bucket               = "use2-cops-tfstates"
    region               = "us-east-2"
    key                  = "prod/bless/kms/terraform.tfstate"
    workspace_key_prefix = "regions"
  }
}
