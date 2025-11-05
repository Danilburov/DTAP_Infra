// Route53 private hosted zone and internal app record

// Private zone associated with VPC
resource "aws_route53_zone" "private_zone" {
  name = var.private_zone_name
  vpc {
    vpc_id = aws_vpc.main.id
  }
  comment = "${var.project} private zone"
}

// app.<zone> alias to ALB
resource "aws_route53_record" "app_internal" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "app.${var.private_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}


