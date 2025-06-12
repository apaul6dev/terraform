variable "vpc_id" {}

resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  vpc_id      = var.vpc_id
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "frontend-sg" }
}

resource "aws_security_group" "backend_alb_sg" {
  name        = "backend-alb-sg"
  vpc_id      = var.vpc_id
  description = "Allow frontend to access backend ALB"

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "backend-alb-sg" }
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  vpc_id      = var.vpc_id
  description = "Allow HTTP from frontend and ALB"

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id, aws_security_group.backend_alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "backend-sg" }
}

output "sg_frontend"     { value = aws_security_group.frontend_sg.id }
output "sg_backend"      { value = aws_security_group.backend_sg.id }
output "sg_backend_alb"  { value = aws_security_group.backend_alb_sg.id }
