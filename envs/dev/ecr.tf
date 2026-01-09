//Here I will create all the respective ECR repos for the deployment
resource "aws_ecr_repository" "iac-dtap-backend-dev"{
    name = "iac-dtap-backend-dev"
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }
}
resource "aws_ecr_repository" "iac-dtap-backend-prod"{
    name = "iac-dtap-backend-prod"
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }
}
resource "aws_ecr_repository" "iac-dtap-frontend-dev"{
    name = "iac-dtap-frontend-dev"
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }
}
resource "aws_ecr_repository" "iac-dtap-frontend-prod"{
    name = "iac-frontend-prod"
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }
}