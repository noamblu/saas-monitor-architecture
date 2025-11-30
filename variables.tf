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

# --- Authentication Configuration ---

variable "auth_type" {
  description = "Authentication type: API_KEY, BASIC, OAUTH, or NONE"
  type        = string
  default     = "API_KEY"
  validation {
    condition     = contains(["API_KEY", "BASIC", "OAUTH", "NONE"], var.auth_type)
    error_message = "auth_type must be one of: API_KEY, BASIC, OAUTH, NONE."
  }
}

variable "api_key_config" {
  description = "Configuration for API_KEY auth"
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "x-api-secret"
    value = "super-secret-api-key-123"
  }
  sensitive = true
}

variable "basic_auth_config" {
  description = "Configuration for BASIC auth"
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "oauth_config" {
  description = "Configuration for OAUTH auth"
  type = object({
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
  })
  default   = null
  sensitive = true
}

# --- Processor Configuration ---

variable "target_url" {
  description = "The URL of the SaaS API to monitor"
  type        = string
  default     = "https://api.example.com/health" # Placeholder
}

variable "event_bus_name" {
  description = "Name of the external EventBridge Bus to send events to"
  type        = string
  default     = "ops-main-cust-bus"
}

# --- VPC Configuration ---

variable "vpc_id" {
  description = "ID of the VPC to use"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Lambda and other resources"
  type        = list(string)
}
