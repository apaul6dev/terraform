terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.secret_region
  access_key = var.access_key
  secret_key = var.secret_key
}

locals {
  extra_tag = "extra-tag"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "unir-vpc"
  }
}

# Subnets Frontend
resource "aws_subnet" "frontend_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "frontend-subnet-1"
  }
}

resource "aws_subnet" "frontend_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "frontend-subnet-2"
  }
}

# Subnets Backend
resource "aws_subnet" "backend_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "backend-subnet-1"
  }
}

resource "aws_subnet" "backend_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "backend-subnet-2"
  }
}

# Internet Gateway & Route Table
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "unir-igw"
  }
}

resource "aws_route_table" "frontend_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "frontend-rt"
  }
}

resource "aws_route_table_association" "frontend_assoc_1" {
  subnet_id      = aws_subnet.frontend_subnet_1.id
  route_table_id = aws_route_table.frontend_rt.id
}

resource "aws_route_table_association" "frontend_assoc_2" {
  subnet_id      = aws_subnet.frontend_subnet_2.id
  route_table_id = aws_route_table.frontend_rt.id
}

# Security Groups
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  vpc_id      = aws_vpc.main.id
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

  tags = {
    Name = "frontend-sg"
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTP from frontend and ALB"

  # Permite tráfico del frontend directamente
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  # Permite tráfico desde el ALB del backend
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }

  # SSH opcional
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sg"
  }
}


# Instancias EC2
resource "aws_instance" "frontend" {
  count                  = 2
  ami                    = "ami-0a7d80731ae1b2435"
  instance_type          = "t2.micro"
  subnet_id              = element([aws_subnet.frontend_subnet_1.id, aws_subnet.frontend_subnet_2.id], count.index)
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  key_name               = var.key_name
  tags = {
    Name     = "frontend-${count.index}"
    ExtraTag = local.extra_tag
  }
}

resource "aws_instance" "backend" {
  count                  = 2
  ami                    = "ami-03fa0cd348172c8fb"
  instance_type          = "t2.micro"
  subnet_id              = element([aws_subnet.backend_subnet_1.id, aws_subnet.backend_subnet_2.id], count.index)
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = var.key_name
  tags = {
    Name     = "backend-${count.index}"
    ExtraTag = local.extra_tag
  }
}

# Frontend ALB
resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.frontend_subnet_1.id,
    aws_subnet.frontend_subnet_2.id
  ]
  security_groups = [aws_security_group.frontend_sg.id]
}

resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "frontend_targets" {
  count            = 2
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend[count.index].id
  port             = 80
}

# Backend ALB
resource "aws_lb" "backend_alb" {
  name               = "backend-alb"
  internal           = true
  load_balancer_type = "application"
  subnets = [
    aws_subnet.backend_subnet_1.id,
    aws_subnet.backend_subnet_2.id
  ]
  security_groups = [aws_security_group.backend_alb_sg.id]
}


resource "aws_security_group" "backend_alb_sg" {
  name        = "backend-alb-sg"
  description = "Allow frontend to access backend ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-alb-sg"
  }
}

# Target group y listener para puerto 8081
resource "aws_lb_target_group" "backend_tg_8081" {
  name     = "backend-tg-8081"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

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

resource "aws_lb_listener" "backend_listener_8081" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 8081
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg_8081.arn
  }
}

resource "aws_lb_target_group_attachment" "backend_targets_8081" {
  count            = 2
  target_group_arn = aws_lb_target_group.backend_tg_8081.arn
  target_id        = aws_instance.backend[count.index].id
  port             = 8081
}
