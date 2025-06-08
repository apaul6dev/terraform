output "ec2_public_ip" {
  description = "La IP pública de la instancia EC2"
  value       = aws_instance.unir_tests.public_ip
}

output "ec2_private_ip" {
  description = "La IP privada de la instancia EC2"
  value       = aws_instance.unir_tests.private_ip
}
