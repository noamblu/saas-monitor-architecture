output "saas_poller_lambda_arn" {
  description = "ARN of the SaaS Poller Lambda"
  value       = module.saas_poller_lambda.arn
}

output "api_destination_arn" {
  description = "ARN of the API Destination"
  value       = module.api_destination.arn
}

output "saas_event_bus_arn" {
  description = "ARN of the dedicated SaaS Event Bus"
  value       = module.event_bus.bus_arn
}

output "lambda_security_group_id" {
  description = "The ID of the Security Group created for Lambda functions"
  value       = module.security_group.id
}
