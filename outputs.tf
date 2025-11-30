output "saas_poller_lambda_arn" {
  description = "The ARN of the SaaS Poller Lambda"
  value       = module.saas_poller_lambda.arn
}

output "api_destination_arn" {
  description = "The ARN of the API Destination"
  value       = module.api_destination.arn
}

output "mock_saas_url" {
  description = "The public URL of the Mock SaaS Lambda (for testing)"
  value       = module.mock_saas_lambda.function_url
}
