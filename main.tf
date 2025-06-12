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

module "vpc" {
  source = "./modules/vpc"
}

module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
}

module "igw" {
  source = "./modules/igw"
  vpc_id = module.vpc.vpc_id
}

module "route_table" {
  source     = "./modules/route_table"
  vpc_id     = module.vpc.vpc_id
  igw_id     = module.igw.igw_id
  subnets_id = module.subnets.frontend_ids
}

module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

module "instances" {
  source           = "./modules/instances"
  subnets_frontend = module.subnets.frontend_ids
  subnets_backend  = module.subnets.backend_ids
  sg_frontend      = module.security_groups.sg_frontend
  sg_backend       = module.security_groups.sg_backend
  sg_backend_alb   = module.security_groups.sg_backend_alb
  key_name         = var.key_name
  extra_tag        = local.extra_tag
}

module "alb_frontend" {
  source       = "./modules/alb_frontend"
  subnets      = module.subnets.frontend_ids
  sg_frontend  = module.security_groups.sg_frontend
  frontend_ids = module.instances.frontend_ids
  vpc_id       = module.vpc.vpc_id
}

module "alb_backend" {
  source         = "./modules/alb_backend"
  subnets        = module.subnets.backend_ids
  sg_backend_alb = module.security_groups.sg_backend_alb
  backend_ids    = module.instances.backend_ids
  vpc_id         = module.vpc.vpc_id
}
