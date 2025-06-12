variable "key_name" {
  description = "Nombre de la clave SSH para acceder a las instancias EC2"
  type        = string
}
variable "secret_region" {
  description = "Región donde se desplegará la infraestructura"
  type        = string
}

variable "access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}
