terraform {
  backend "s3" {
    encrypt              = "true"
    bucket               = "use2-cops-tfstates"
    dynamodb_table       = "use2-cops-terraform-remote-state"
    region               = "us-east-2"
    key                  = "prod/bless/kms/terraform.tfstate"
    workspace_key_prefix = "regions"
  }
}
