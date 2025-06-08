# Infraestructura UNIR - Node.js + Nginx con Packer y Terraform

## Estructura

- `packer/`: Crea una imagen AMI personalizada con Node.js y Nginx.
- `terraform/`: Provisiona red, SG, e instancia EC2 basada en la AMI creada.

## Pasos

### 1. Crear imagen con Packer

```bash
cd packer
packer build -var 'aws_access_key=...' -var 'aws_secret_key=...' -var 'aws_region=us-east-1' packer-node-nginx.json
