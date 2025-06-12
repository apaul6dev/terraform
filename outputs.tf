output "vpc_id" {
  description = "ID de la VPC principal"
  value       = module.vpc.vpc_id
}

output "frontend_subnets" {
  description = "IDs de las subnets públicas (frontend)"
  value       = module.subnets.frontend_ids
}

output "backend_subnets" {
  description = "IDs de las subnets privadas (backend)"
  value       = module.subnets.backend_ids
}

output "frontend_instances" {
  description = "IDs de instancias EC2 del frontend"
  value       = module.instances.frontend_ids
}

output "backend_instances" {
  description = "IDs de instancias EC2 del backend"
  value       = module.instances.backend_ids
}

# ======================
# IPs y DNS del Frontend - backend
# ======================

output "frontend_alb_dns" {
  description = "DNS del Load Balancer del frontend"
  value       = module.alb_frontend.dns_name
}

output "backend_alb_dns" {
  description = "DNS del Load Balancer del backend (interno)"
  value       = module.alb_backend.dns_name
}

# IPs y DNS del Frontend (públicos)
output "frontend_public_ips" {
  description = "IPs públicas de las instancias frontend"
  value       = module.instances.frontend_public_ips
}

output "frontend_public_dns" {
  description = "DNS públicos de las instancias frontend"
  value       = module.instances.frontend_public_dns
}

# IPs y DNS del Backend (privados)
output "backend_private_ips" {
  description = "IPs privadas de las instancias backend"
  value       = module.instances.backend_private_ips
}

output "backend_private_dns" {
  description = "DNS privados de las instancias backend"
  value       = module.instances.backend_private_dns
}
