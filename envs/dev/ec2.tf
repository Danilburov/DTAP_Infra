// EC2 launch template and Auto Scaling Group for app

// Amazon Linux 2023 AMI for app instances
data "aws_ami" "al2023_app" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

// Launch template for app instances (IMDSv2 required)
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-app-"
  image_id      = data.aws_ami.al2023_app.id
  instance_type = var.app_instance_type

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = filebase64("${path.module}/user_data.sh")

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "${var.project}-app" })
  }
}

// Auto Scaling Group for app
resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-asg"
  vpc_zone_identifier = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
  min_size            = 1
  desired_capacity    = 1
  max_size            = 2
  health_check_type   = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.project}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

