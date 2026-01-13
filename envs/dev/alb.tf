// Application Load Balancer, target group, and listener

// Internet-facing ALB in public subnets
resource "aws_lb" "app_alb" {
  name               = "${var.project}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = merge(var.tags, { Name = "${var.project}-app-alb" })
}

// Target group for app instances
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 60
    timeout             = 15
  }

  tags = merge(var.tags, { Name = "${var.project}-app-tg" })
}

// HTTP listener forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
//New ALB for the backend ECS
resource "aws_alb" "dtap-backend-alb" {
  name = "dtap-backend-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.dtap-backend-alb-sg.id]
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

//Target group for the dtap-backend-alb
resource "aws_alb_target_group" "dtap-backend-tg"{
  name = "dtap-backend-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip" //This is added manually, the default is 'instance' and to be able to wire it to the task definitions to create the ECS service it needs to be taget type 'ip' because of the 'awsvpc' protocol

  health_check {
    path = "/health"
    matcher = "200"
    healthy_threshold = 2
    unhealthy_threshold = 5
    interval = 60
    timeout = 15
  } 
}

//Listner to wire the backend-tg to the backend-alb
resource "aws_alb_listener" "dtap_backend-http" {
  load_balancer_arn = aws_alb.dtap-backend-alb.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.dtap-backend-tg.arn
  }
}
resource "aws_alb" "dtap-frontend-alb" {
  name = "dtap-frontend-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.dtap-frontend-alb-sg.id]
  subnets = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}
resource "aws_alb_target_group" "dtap-frontend-tg"{
  name = "dtap-frontend-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path = "/"
    matcher = "200"
    healthy_threshold = 2
    unhealthy_threshold = 5
    interval = 60
    timeout = 15
  } 
}
resource "aws_alb_listener" "dtap_frontend-http" {
  load_balancer_arn = aws_alb.dtap-frontend-alb.arn
  port = 80
  protocol = "HTTP"
  
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.dtap-frontend-tg.arn
  }
}