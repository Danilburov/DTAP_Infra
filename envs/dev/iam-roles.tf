//Role for the ECS tasks to write logs into Firehose
resource "aws_iam_role_policy" "ecs_task_firehose" {
  name = "${var.project}-ecs-task-firehose"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["firehose:PutRecord", "firehose:PutRecordBatch"],
      Resource = aws_kinesis_firehose_delivery_stream.ecs_app_logs.arn
    }]
  })
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
// IAM role allowing EC2 describe for service discovery
data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "monitoring_role" {
  name               = "${var.project}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
}

data "aws_iam_policy_document" "monitoring_inline" {
  statement {
    actions   = ["ec2:DescribeInstances", "ec2:DescribeTags"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "monitoring_policy" {
  name   = "${var.project}-monitoring-ec2-describe"
  role   = aws_iam_role.monitoring_role.id
  policy = data.aws_iam_policy_document.monitoring_inline.json
}

resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "${var.project}-monitoring-profile"
  role = aws_iam_role.monitoring_role.name
}
//First Roles for the creation of a task definition
resource "aws_iam_role" "ecs_execution" {
    name = "dtap-ecs-execution-role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "vpn_role" {
  name = "${var.project}-vpn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpn_s3_policy" {
  name = "${var.project}-vpn-s3-policy"
  role = aws_iam_role.vpn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject","s3:GetObject","s3:ListBucket"],
      Resource = [
        data.terraform_remote_state.persistent.outputs.vpn_pki_bucket_arn,
        "${data.terraform_remote_state.persistent.outputs.vpn_pki_bucket_arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "vpn_profile" {
  name = "${var.project}-vpn-profile"
  role = aws_iam_role.vpn_role.name
}
