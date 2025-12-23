output "arn" {
  value = aws_cloudwatch_event_api_destination.this.arn
}

output "connection_arn" {
  value = aws_cloudwatch_event_connection.this.arn
}

output "name" {
  value = aws_cloudwatch_event_api_destination.this.name
}

output "connection_name" {
  value = aws_cloudwatch_event_connection.this.name
}

output "connection_secret_arn" {
  value = aws_cloudwatch_event_connection.this.secret_arn
}
