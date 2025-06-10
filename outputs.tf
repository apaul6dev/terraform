# Outputs
output "frontend_public_ips" {
  value = [for instance in aws_instance.frontend : instance.public_ip]
}

output "backend_private_ips" {
  value = [for instance in aws_instance.backend : instance.private_ip]
}

output "frontend_alb_dns" {
  value = aws_lb.frontend_alb.dns_name
}

output "backend_alb_dns" {
  value = aws_lb.backend_alb.dns_name
}
