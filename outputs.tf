output "saas_poller_lambda_arn" {
  description = "The ARN of the SaaS Poller Lambda"
  value       = module.saas_poller_lambda.arn
}

output "api_destination_arn" {
  description = "The ARN of the API Destination"
  value       = module.api_destination.arn
}

output "mock_saas_url" {
  description = "The URL of the Mock SaaS API"
  value       = module.mock_saas_lambda.function_url
}

output "lambda_security_group_id" {
  description = "The ID of the Security Group created for Lambda functions"
  value       = aws_security_group.lambda_sg.id
}
