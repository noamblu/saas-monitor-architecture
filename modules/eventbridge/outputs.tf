output "bus_arn" {
  value = aws_cloudwatch_event_bus.this.arn
}

output "bus_name" {
  value = aws_cloudwatch_event_bus.this.name
}

output "log_group_arn" {
  value = var.log_group_name != null ? aws_cloudwatch_log_group.this[0].arn : null
}
