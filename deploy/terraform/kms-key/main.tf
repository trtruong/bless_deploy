resource "aws_kms_key" "BLESS" {
  description             = "BLESS KMS for ${terraform.workspace}"
  deletion_window_in_days = 10

  tags = "${merge(
    module.constants_global.tags_default_cloud-ops,
    map(
      "fp-environment", "prod",
      "STAGE", "p"
    ),
  )}"
}

resource "aws_kms_alias" "BLESS" {
  name          = "alias/BLESS-${terraform.workspace}"
  target_key_id = "${aws_kms_key.BLESS.key_id}"
}

variable "REGION" {
  type    = "string"
  default = "us-east-2"
}
