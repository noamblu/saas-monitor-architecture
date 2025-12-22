variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS Profile to use for authentication"
  type        = string
  default     = "sandbox"
}

variable "saas_name" {
  description = "The name of the SaaS application"
  type        = string
  default     = "noam-saas"
}

variable "auth_config" {
  description = "Authentication configuration"
  type = object({
    mode = string # API_KEY, BASIC, OAUTH, NONE
    api_key = optional(object({
      key   = string
      value = string
    }))
    basic = optional(object({
      username = string
      password = string
    }))
    oauth = optional(object({
      authorization_endpoint = string
      http_method            = string
      client_parameters = object({
        client_id     = string
        client_secret = string
      })
      oauth_http_parameters = optional(object({
        header       = optional(list(object({ key = string, value = string, is_value_secret = optional(bool, false) })))
        body         = optional(list(object({ key = string, value = string, is_value_secret = optional(bool, false) })))
        query_string = optional(list(object({ key = string, value = string, is_value_secret = optional(bool, false) })))
      }))
    }))
  })
  default = {
    mode = "API_KEY"
    api_key = {
      key   = "x-api-secret"
      value = "super-secret-api-key-123"
    }
  }
}

variable "target_url" {
  description = "The URL of the SaaS API to monitor"
  type        = string
  default     = "https://api.example.com/health"
}

variable "ops_main_events_bus_name" {
  description = "Name of the central operational-main-events-bus"
  type        = string
  default     = "operational-main-events-bus"
}

variable "api_destination_name" {
  description = "Name of the API Destination (optional, defaults to saas_name)"
  type        = string
  default     = null
}

variable "connection_name" {
  description = "Name of the Connection (optional, defaults to saas_name)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default = {
    Project     = "SaaS-Monitor"
    ManagedBy   = "Terraform"
    Environment = "Sandbox"
  }
}

variable "lambda_layer_name" {
  description = "Name of the existing Lambda Layer to use."
  type        = string
  default     = "saas-monitor-dependencies-layer"
}

variable "schema_registry_name" {
  description = "Name of the existing Schema Registry to use"
  type        = string
  default     = "saas-events-registry"
}
