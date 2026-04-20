# Exposing the values of main.tf of module vpc to the principal main.tf
output "private_subnets" {
  value = aws_subnet.private[*].id
}