resource "aws_ecs_cluster" "frontend"{
    name = "dtap-frontend-cluster"

    setting{
        name = "containerInsights"
        value = "enabled"
    }
}
resource "aws_ecs_cluster" "backend"{
    name = "dtap-backend-cluster"

    setting{
        name = "containerInsight"
        value = "enabled"
    }
}