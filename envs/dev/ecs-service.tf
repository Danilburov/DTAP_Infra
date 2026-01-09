//Roles for the creation of a task definition
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



//First I will create the task definitions for each ECR that I registered
# resource "aws_ecs_task_definition" "frontend_bootstrap"{
#     family = "iac-dtap-frontend"
#     requires_compatibilities = ["FARGATE"]
#     network_mode = "awsvpc"
#     cpu = "256"
#     memory = "512"

#     execution_role_arn = aws_iam_role.ecs_execution.arn
# }
# resource "aws_ecs_task_definition" "iac-dtap-backend-dev"{
#     family = "iac-dtap-backend-dev"
#     requires_compatibilities = ["FARGATE"]
#     network_mode = "awsvpc"
#     cpu = tostring(var.backend_cpu)
#     memory = tostring(var.backend_memory)

#     execution_role_arn = var.ecs
# }
# resource "aws_ecs_task_definition" "iac-dtap-backend-prod"{}
# resource "aws_ecs_task_definition" "iac-dtap-frontend-dev"{}
# resource "aws_ecs_task_definition" "iac-dtap-frontend-prod"{}