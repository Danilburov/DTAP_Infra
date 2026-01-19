//Within this file I will initialize Firehose, which will deliver real-time streaming data to an S3 bucket

data "aws_caller_identity" "current" {}

//The S3 bucket where the application logs will go to
resource "aws_s3_bucket" "ecs_app_logs" {
    bucket = "dtap-ecs-app-logs"
    force_destroy = true
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
    error_output_prefix = "ecs/app-errors/!{firehose:error-output-type}/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    compression_format = "GZIP"
    buffering_interval = 60
    buffering_size     = 5
  }
}
//New cloudwatch group for firelens (Fluent bit)
resource "aws_cloudwatch_log_group" "firelens" {
  name = "/ecs/dtap/firelens"
  retention_in_days = 7
}