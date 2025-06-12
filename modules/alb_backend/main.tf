variable "subnets" {}
variable "sg_backend_alb" {}
variable "backend_ids" {}
variable "vpc_id" {}

resource "aws_lb" "alb" {
  name               = "backend-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [var.sg_backend_alb]
}

resource "aws_lb_target_group" "tg" {
  name     = "backend-tg-8081"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8081
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.backend_ids[count.index]
  port             = 8081
}

output "dns_name" {
  description = "DNS interno del ALB de backend"
  value       = aws_lb.alb.dns_name
}