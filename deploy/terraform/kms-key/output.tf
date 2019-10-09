output "keyId" {
  value = "${aws_kms_key.BLESS.key_id}"
}

output "key_arn" {
  value = "${aws_kms_key.BLESS.arn}"
}
