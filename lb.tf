resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.test_subnet_public_1.id, aws_subnet.test_subnet_public_2.id]
}

resource "aws_lb_target_group" "wordpress_alb_target_group" {
  name     = "wordpress-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
}

resource "aws_lb_listener" "wordpres_alb_listener_http" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "lordpres_alb_listener_https" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn
  default_action {
    target_group_arn = aws_lb_target_group.wordpress_alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "lordpres_alb_listener_httpscert" {
  listener_arn    = aws_alb_listener.lordpres_alb_listener_https.arn
  certificate_arn = data.aws_acm_certificate.issued.arn
}

resource "aws_route53_record" "myRecord" {
  zone_id = data.aws_route53_zone.myZone.zone_id
  name    = "www"
  type    = "A"

  alias {
      name                   = aws_lb.wordpress_alb.dns_name
      zone_id                = aws_lb.wordpress_alb.zone_id
      evaluate_target_health = true
  }
}
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.id
  alb_target_group_arn   = aws_lb_target_group.wordpress_alb_target_group.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.wordpress_alb.dns_name
}
