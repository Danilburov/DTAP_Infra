resource "aws_ecs_service" "dtap-backend-dev" {
  name = "dtap-backend-dev"
  cluster = aws_ecs_cluster.dtap-cluster.arn
  task_definition = aws_ecs_task_definition.iac-dtap-backend-dev.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_service_backend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.dtap-backend-tg.arn
    container_name = "backend"
    container_port = 8080
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
resource "aws_ecs_service" "dtap-frontend-dev" {
  name = "dtap-frontend-dev"
  cluster = aws_ecs_cluster.dtap-cluster.arn
  task_definition = aws_ecs_task_definition.iac-dtap-frontend-dev.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups = [aws_security_group.ecs_service_frontend_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.dtap-frontend-tg.arn
    container_name = "frontend"
    container_port = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

