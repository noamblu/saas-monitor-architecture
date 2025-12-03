output "registry_name" {
  description = "Name of the Schema Registry"
  value       = aws_schemas_registry.this.name
}

output "registry_arn" {
  description = "ARN of the Schema Registry"
  value       = aws_schemas_registry.this.arn
}

output "schemas" {
  description = "Map of created schemas"
  value       = aws_schemas_schema.this
}
