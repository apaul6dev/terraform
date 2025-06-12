variable "vpc_id" {}

resource "aws_subnet" "frontend_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "frontend-subnet-1" }
}

resource "aws_subnet" "frontend_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "frontend-subnet-2" }
}

resource "aws_subnet" "backend_1" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "backend-subnet-1" }
}

resource "aws_subnet" "backend_2" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "backend-subnet-2" }
}

output "frontend_ids" {
  value = [aws_subnet.frontend_1.id, aws_subnet.frontend_2.id]
}

output "backend_ids" {
  value = [aws_subnet.backend_1.id, aws_subnet.backend_2.id]
}
