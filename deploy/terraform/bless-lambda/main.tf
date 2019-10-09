resource "aws_iam_role" "bless_lambda" {
  name = "bless_lambda_role-${terraform.workspace}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = "${merge(
    module.constants_global.tags_default_cloud-ops,
    map(
      "fp-environment", "prod",
      "STAGE", "p"
    ),
  )}"
}

resource "aws_iam_policy" "bless_lambda_policy" {
  name        = "bless_lambda_policy-${terraform.workspace}"
  description = "bless_lambda_policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "Stmt1443036478000",
          "Effect": "Allow",
          "Action": [
              "kms:GenerateRandom",
              "kms:Decrypt"
          ],
          "Resource": [
              "${data.terraform_remote_state.bless-kms.key_arn}"
          ]
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${terraform.workspace}:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${terraform.workspace}:*:log-group:/aws/lambda/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "xray:PutTelemetryRecords",
                "xray:PutTraceSegments"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment-${terraform.workspace}"
  roles      = ["${aws_iam_role.bless_lambda.name}"]
  policy_arn = "${aws_iam_policy.bless_lambda_policy.arn}"
}

resource "aws_lambda_function" "BLESS" {
  filename         = "../../bless/publish/bless_lambda.zip"
  function_name    = "BLESS-${terraform.workspace}"
  role             = "${aws_iam_role.bless_lambda.arn}"
  handler          = "bless_lambda.lambda_handler"
  source_code_hash = "${base64sha256(file("../../bless/publish/bless_lambda.zip"))}"
  runtime          = "python3.7"
  kms_key_arn      = "${data.terraform_remote_state.bless-kms.key_arn}"
  timeout          = 30
  tracing_config   {
       mode = "Active"
       }

  tags = "${merge(
      module.constants_global.tags_default_cloud-ops,
      map(
        "fp-environment", "prod",
        "STAGE", "p"
      ),
    )}"
}
