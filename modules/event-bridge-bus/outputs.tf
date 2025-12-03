output "bus_name" {
  description = "Name of the EventBridge Bus"
  value       = aws_cloudwatch_event_bus.this.name
}

output "bus_arn" {
  description = "ARN of the EventBridge Bus"
  value       = aws_cloudwatch_event_bus.this.arn
}

output "rules" {
  description = "Map of created rules"
  value       = aws_cloudwatch_event_rule.this
}
