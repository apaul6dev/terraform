# Infraestructura UNIR - Node.js + Nginx con Packer y Terraform

## Estructura

- `packer/`: Crea una imagen AMI personalizada con Node.js y Nginx.
- `terraform/`: Provisiona red, SG, e instancia EC2 basada en la AMI creada.

- crear:  terraform.tfvars

        access_key    = "**********"
        secret_key    = "**********"
        secret_region = "us-east-1"

- crear:  packer/packer.auto.pkrvars.json

        {
            "aws_access_key": "**********",
            "aws_secret_key": "**********",
            "aws_region": "us-east-1"
        }


## Pasos

### 1. Crear imagen con Packer

cd packer                         
packer build -var-file="packer.auto.pkrvars.json" packer-node-backend.json 
packer build -var-file="packer.auto.pkrvars.json" packer-node-front.json 

### 1. Ejecutar terraform

terraform init
terraform plan
terraform apply
terraform destroy
