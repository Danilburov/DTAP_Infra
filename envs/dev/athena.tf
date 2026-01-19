resource "aws_s3_bucket" "athena_results" {
  bucket = "dtap-athena-results"
  force_destroy = true
}
resource "aws_athena_database" "ecs_logs" {
  name = "ecs_logs"
  bucket = aws_s3_bucket.athena_results.bucket
}
resource "aws_athena_named_query" "ecs_app_logs_table" {
  name = "create_ecs_app_logs_table"
  database = aws_athena_database.ecs_logs.name
  query = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS ecs_app_logs (
  container_id string,
  container_name string,
  ecs_cluster string,
  ecs_task_arn string,
  ecs_task_definition string,
  log string,
  source string
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://${aws_s3_bucket.ecs_app_logs.bucket}/ecs/app/';
EOF
}
