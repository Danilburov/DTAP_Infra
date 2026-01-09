resource "aws_ecs_cluster" "dtap-cluster"{
    name = "dtap-cluster"

    setting{
        name = "containerInsights"
        value = "enabled"
    }
}