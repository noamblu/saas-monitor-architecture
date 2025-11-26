output "mock_saas_url" {
  description = "The public URL of the Mock SaaS Lambda"
  value       = module.mock_saas_lambda.function_url
}

output "processor_lambda_arn" {
  description = "The ARN of the Processor Lambda"
  value       = module.processor_lambda.arn
}
