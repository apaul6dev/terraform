variable "subnets_frontend" { type = list(string) }
variable "subnets_backend" { type = list(string) }
variable "sg_frontend" {}
variable "sg_backend" {}
variable "sg_backend_alb" {}
variable "key_name" {}
variable "extra_tag" {}

resource "aws_instance" "frontend" {
  count                  = 2
  ami                    = "ami-0a7d80731ae1b2435"
  instance_type          = "t2.micro"
  subnet_id              = element(var.subnets_frontend, count.index)
  vpc_security_group_ids = [var.sg_frontend]
  key_name               = var.key_name

  tags = {
    Name     = "frontend-${count.index}"
    ExtraTag = var.extra_tag
  }
}

resource "aws_instance" "backend" {
  count                  = 2
  ami                    = "ami-03fa0cd348172c8fb"
  instance_type          = "t2.micro"
  subnet_id              = element(var.subnets_backend, count.index)
  vpc_security_group_ids = [var.sg_backend]
  key_name               = var.key_name

  tags = {
    Name     = "backend-${count.index}"
    ExtraTag = var.extra_tag
  }
}

output "frontend_ids" {
  value = aws_instance.frontend[*].id
}

output "backend_ids" {
  value = aws_instance.backend[*].id
}

# IPs públicas de frontend
output "frontend_public_ips" {
  description = "IPs públicas de las instancias frontend"
  value       = aws_instance.frontend[*].public_ip
}

output "frontend_public_dns" {
  description = "DNS públicos de las instancias frontend"
  value       = aws_instance.frontend[*].public_dns
}

# IPs privadas de backend
output "backend_private_ips" {
  description = "IPs privadas de las instancias backend"
  value       = aws_instance.backend[*].private_ip
}

output "backend_private_dns" {
  description = "DNS privados de las instancias backend"
  value       = aws_instance.backend[*].private_dns
}

