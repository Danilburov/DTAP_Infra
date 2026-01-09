# resource "aws_ecs_service" "dtap-backend-dev" {
#   name = "dtap-backend-dev"
#   cluster = aws_ecs_cluster.backend.arn
#   task_definition = aws_ecs_task_definition.iac-dtap-backend-dev.arn
#   desired_count = 1
#   launch_type = "FARGATE"

#   network_configuration {
#     subnets = var.private_subnet_ids
#     security_groups = [aws_security_group.backend_tasks_sg.id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_alb_target_group.dtap-backend-tg.arn
#     container_name = "backend"
#     container_port = 8080
#   }

#   lifecycle {
#     ignore_changes = [task_definition]
#   }
# }
