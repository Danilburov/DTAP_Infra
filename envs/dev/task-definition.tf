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

//Then I will create the task definitions for each ECR that I registered

//Both the dev and prod environments will use the same template image that I deployed via GitLab. This image is their project but quite behind and it is working for sure.
//This is done just to create the task definitions, after that with the usage of GitLab pipelines I will create new revisions of these task definitions and update them accordingly.

//DTAP-FRONTEND-DEV Task definition
resource "aws_ecs_task_definition" "iac-dtap-frontend-dev"{
    family = "iac-dtap-frontend-dev"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"

    execution_role_arn = aws_iam_role.ecs_execution.arn
    task_role_arn = aws_iam_role.ecs_task.arn

    container_definitions = jsonencode([{
        name = "frontend"
        image = "${aws_ecr_repository.iac-dtap-frontend-dev.repository_url}:${var.backend_dev_image_tag}"
        essential = true
        portMappings = [{ containerPort = 80, protocol = "tcp" }]
  }])
}
//DTAP-FRONTEND-PROD Task definition
resource "aws_ecs_task_definition" "iac-dtap-frontend-prod"{
    family = "iac-dtap-frontend-prod"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"

    execution_role_arn = aws_iam_role.ecs_execution.arn
    task_role_arn = aws_iam_role.ecs_task.arn

    container_definitions = jsonencode([{
        name = "frontend"
        image = "${aws_ecr_repository.iac-dtap-frontend-dev.repository_url}:${var.frontend_dev_image_tag}"
        essential = true
        portMappings = [{ containerPort = 80, protocol = "tcp" }]
  }])
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

  container_definitions = jsonencode([
    {
      name = "backend"
      image = aws_ecr_repository.iac-dtap-backend-dev.repository_url
      essential = true

      portMappings = [{
          containerPort = 8080
          protocol = "tcp"
        }]
      environment = [
        {
          name = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://dtap-db.cxciqio0qcm4.eu-central-1.rds.amazonaws.com:5432/postgres"
        },
        {
          name = "SPRING_DATASOURCE_USERNAME"
          value = "postgres"
        },
        {
          name  = "SPRING_DATASOURCE_PASSWORD"
          value = "rWahgRZsoLHKAJHxquwvGsCLs"
        }
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
    {
      name = "backend"
      image = aws_ecr_repository.iac-dtap-backend-dev.repository_url
      essential = true

      portMappings = [{
          containerPort = 8080
          protocol = "tcp"
        }]
      environment = [
        {
          name = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://dtap-db.cxciqio0qcm4.eu-central-1.rds.amazonaws.com:5432/postgres"
        },
        {
          name = "SPRING_DATASOURCE_USERNAME"
          value = "postgres"
        },
        {
          name  = "SPRING_DATASOURCE_PASSWORD"
          value = "rWahgRZsoLHKAJHxquwvGsCLs"
        }
      ]
    }
  ])
}