//Within this file I will initialize Firehose, which will deliver real-time streaming data to an S3 bucket

data "aws_caller_identity" "current" {}

//The S3 bucket where the application logs will go to
resource "aws_s3_bucket" "ecs_app_logs" {
    bucket = "dtap-ecs-app-logs"
    force_destroy = true
}

//I need to create a new role for Firehose to write into the S3 bucket
resource "aws_iam_role" "firehose_role" {
    name = "dtap-ecs-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "firehose.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "firehose_to_s3" {
  name = "${var.project}-firehose-to-s3"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      Resource = [
        aws_s3_bucket.ecs_app_logs.arn,
        "${aws_s3_bucket.ecs_app_logs.arn}/*"
      ]
    }]
  })
}
//this part is taken from the official terraform docs for using firehose as a delivery stream
//link: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream
resource "aws_kinesis_firehose_delivery_stream" "ecs_app_logs" {
  name = "dtap-ecs-app-logs"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.ecs_app_logs.arn

    prefix = "ecs/app/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    error_output_prefix = "ecs/app-errors/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    compression_format = "GZIP"
    buffering_interval = 60
    buffering_size     = 5
  }
}
