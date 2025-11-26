output "arn" {
  value = aws_cloudwatch_event_api_destination.this.arn
}

output "connection_arn" {
  value = aws_cloudwatch_event_connection.this.arn
}
