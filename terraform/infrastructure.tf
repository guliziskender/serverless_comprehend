resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "kinesis-firehose-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  destination = "extended_s3"
#  cloudwatch_logging_options {
#    enabled = true
#        log_group_name = data.aws_region.current.name/firehose/log-group
#      }
#  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "kinesis-firehose-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

## TODO: Solve this issue

resource "aws_s3_bucket_ownership_controls" "mybucket2-acl-ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "iam_policy_for_firehose" {
 name         = "aws_iam_policy_for_firehose"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "s3:AbortMultipartUpload",
       "s3:GetBucketLocation",
       "s3:GetObject",
       "s3:ListBucket",
       "s3:ListBucketMultipartUploads",
       "s3:PutObject"
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_firehose_log" {
 name         = "aws_iam_policy_for_firehose_logging"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_firehose_function" {
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "lambda:InvokeFunction",
       "logs:CreateLogStream",
       "logs:PutLogEvents",
       "lambda:GetFunctionConfiguration"
     ],
     "Resource": "${aws_lambda_function.lambda_processor.arn}:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_firehose_policy_log" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.iam_policy_for_firehose_log.arn
}

resource "aws_iam_role_policy_attachment" "attach_firehose_policy_function" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.iam_policy_for_firehose_function.arn
}

resource "aws_iam_role_policy_attachment" "attach_firehose_policy" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.iam_policy_for_firehose.arn
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "iam_policy_for_lambda" {

 name         = "aws_iam_policy_for_lambda"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda_service" {

 name         = "aws_iam_policy_for_lambda_service"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "firehose:PutRecord",
       "firehose:PutRecordBatch",
       "comprehend:DetectPiiEntities",
       "comprehend:ContainsPiiEntities",
       "comprehend:BatchDetectDominantLanguage"
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda_twitter" {

 name         = "aws_iam_policy_for_lambda_service_twitter"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "firehose:PutRecord",
       "firehose:PutRecordBatch",
       "comprehend:DetectPiiEntities",
       "comprehend:ContainsPiiEntities",
       "comprehend:BatchDetectDominantLanguage",
       "ec2:DescribeNetworkInterfaces",
       "ec2:CreateNetworkInterface",
       "ec2:DeleteNetworkInterface",
       "ec2:DescribeInstances",
       "ec2:AttachNetworkInterface"
     ],
     "Resource": "*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_iam"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "lambda_iam_twitter" {
  name               = "lambda_iam_twitter"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_twitter" {
  role       = aws_iam_role.lambda_iam_twitter.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_twitter.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy_service" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_service.arn
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "lambda.py.zip" ##To be changed
  function_name = "firehose_lambda_processor"
  role          = aws_iam_role.lambda_iam.arn
  handler       = "exports.handler"
  runtime       = "python3.9"
  timeout       = 300
  layers        = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-boto3:15"]
}

resource "aws_lambda_function" "lambda_get_data" {
  filename      = "lambda.py.zip" ##To be changed
  function_name = "lambda_get_data_twitter"
  role          = aws_iam_role.lambda_iam_twitter.arn
  handler       = "exports.handler"
  runtime       = "python3.9"
  timeout       = 300
  layers        = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-boto3:15", "arn:aws:lambda:us-east-1:770693421928:layer:Klayers-python38-tweepy:1"]

  vpc_config {
  subnet_ids         = [module.vpc.public_subnets[0]]
  security_group_ids = [aws_security_group.allow_https.id]
}
}
