//Then I will create the task definitions for each ECR that I registered

//Both the dev and prod environments will use the same template image that I deployed via GitLab. This image is their project but quite behind and it is working for sure.
//This is done just to create the task definitions, after that with the usage of GitLab pipelines I will create new revisions of these task definitions and update them accordingly.

//DTAP-FRONTEND-DEV Task definition
resource "aws_ecs_task_definition" "iac-dtap-frontend-dev" {
  family = "iac-dtap-frontend-dev"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name = "log_router"
      image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region = var.region
          awslogs-group = aws_cloudwatch_log_group.firelens.name
          awslogs-stream-prefix = "firelens"
        }
      }
    },

    #container definition
    {
      name = "frontend"
      image = "${aws_ecr_repository.iac-dtap-frontend-dev.repository_url}:${var.backend_dev_image_tag}"
      essential = true

      portMappings = [
        { containerPort = 80, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name = "firehose"
          region = var.region
          delivery_stream = aws_kinesis_firehose_delivery_stream.ecs_app_logs.name
        }
      }
      dependsOn = [
        { containerName = "log_router", condition = "START" }
      ]
    }
  ])
}

//DTAP-FRONTEND-PROD Task definition
resource "aws_ecs_task_definition" "iac-dtap-frontend-prod" {
  family = "iac-dtap-frontend-prod"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      //firelens definition
      name = "log_router"
      image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region = var.region
          awslogs-group = aws_cloudwatch_log_group.firelens.name
          awslogs-stream-prefix = "firelens"
        }
      }
    },
    //container definition
    {
      name = "frontend"
      image = "${aws_ecr_repository.iac-dtap-frontend-dev.repository_url}:${var.frontend_dev_image_tag}"
      essential = true

      portMappings = [
        { containerPort = 80, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name = "firehose"
          region = var.region
          delivery_stream = aws_kinesis_firehose_delivery_stream.ecs_app_logs.name
        }
      }
      dependsOn = [
        { containerName = "log_router", condition = "START" }
      ]
    }
  ])
}


//DTAP-BACKEND-DEV Task definition
resource "aws_ecs_task_definition" "iac-dtap-backend-dev" {
  family = "iac-dtap-backend-dev"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

//Only change will be here for the task definitions, I need to ensure that the container logs are collected by Fluent bit
container_definitions = jsonencode([
  {
    name = "log_router"
    image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
    essential = true

    firelensConfiguration = {
      type = "fluentbit"
      options = {
        enable-ecs-log-metadata = "true"
      }
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-region = var.region
        awslogs-group = aws_cloudwatch_log_group.firelens.name
        awslogs-stream-prefix = "firelens"
      }
    }
  },
  //the backend container is defined here
  {
    name = "backend"
    image = aws_ecr_repository.iac-dtap-backend-dev.repository_url
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol = "tcp"
    }]

    environment = [
      { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://dtap-db.cxciqio0qcm4.eu-central-1.rds.amazonaws.com:5432/postgres" },
      { name = "SPRING_DATASOURCE_USERNAME", value = "postgres" },
      { name = "SPRING_DATASOURCE_PASSWORD", value = "rWahgRZsoLHKAJHxquwvGsCLs" }
    ]

    #here is the actual pipeline implementation: app logs - FireLens - Firehose - S3
    logConfiguration = {
      logDriver = "awsfirelens"
      options = {
        Name = "firehose"
        region = var.region
        delivery_stream = aws_kinesis_firehose_delivery_stream.ecs_app_logs.name
      }
    }
    dependsOn = [
      { containerName = "log_router", condition = "START" }
    ]
  }
])
}

//DTAP-BACKEND-PROD Task definition
resource "aws_ecs_task_definition" "iac-dtap-backend-prod" {
  family = "iac-dtap-backend-prod"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    # FireLens log router definition
    {
      name = "log_router"
      image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential = true

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region = var.aws.region
          awslogs-group = aws_cloudwatch_log_group.firelens.name
          awslogs-stream-prefix = "firelens"
        }
      }
    },

    # Backend container
    {
      name = "backend"
      image = aws_ecr_repository.iac-dtap-backend-prod.repository_url
      essential = true

      portMappings = [{
        containerPort = 8080
        protocol = "tcp"
      }]

      environment = [
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://dtap-db.cxciqio0qcm4.eu-central-1.rds.amazonaws.com:5432/postgres" },
        { name = "SPRING_DATASOURCE_USERNAME", value = "postgres" },
        { name = "SPRING_DATASOURCE_PASSWORD", value = "rWahgRZsoLHKAJHxquwvGsCLs" }
      ]

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name = "firehose"
          region = var.region
          delivery_stream = aws_kinesis_firehose_delivery_stream.ecs_app_logs.name
        }
      }

      dependsOn = [
        { containerName = "log_router", condition = "START" }
      ]
    }
  ])
}