variable "subnets" {}
variable "sg_frontend" {}
variable "frontend_ids" {}
variable "vpc_id" {}

resource "aws_lb" "alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets
  security_groups    = [var.sg_frontend]
}

resource "aws_lb_target_group" "tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.frontend_ids[count.index]
  port             = 80
}

output "dns_name" {
  description = "DNS público del ALB de frontend"
  value       = aws_lb.alb.dns_name
}