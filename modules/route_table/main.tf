variable "vpc_id" {}
variable "igw_id" {}
variable "subnets_id" {
  type = list(string)
}

resource "aws_route_table" "frontend_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = { Name = "frontend-rt" }
}

resource "aws_route_table_association" "assoc" {
  count          = length(var.subnets_id)
  subnet_id      = var.subnets_id[count.index]
  route_table_id = aws_route_table.frontend_rt.id
}