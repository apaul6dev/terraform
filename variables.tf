variable "access_key" {
  description = "access_key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "secret_key"
  type        = string
  sensitive   = true
}

variable "secret_region" {
  description = "secret_region"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Nombre del par de claves SSH en AWS"
  type        = string
}
