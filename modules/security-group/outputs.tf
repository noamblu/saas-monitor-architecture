output "id" {
  description = "ID of the Security Group"
  value       = aws_security_group.this.id
}

output "arn" {
  description = "ARN of the Security Group"
  value       = aws_security_group.this.arn
}
