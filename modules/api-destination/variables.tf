variable "name" {
  description = "Base name for connection and destination"
  type        = string
}

variable "invocation_endpoint" {
  description = "URL to invoke"
  type        = string
}

variable "http_method" {
  description = "HTTP method"
  type        = string
  default     = "GET"
}

variable "auth_type" {
  description = "Authentication type: API_KEY, BASIC, OAUTH, or NONE"
  type        = string
  default     = "API_KEY"
  validation {
    condition     = contains(["API_KEY", "BASIC", "OAUTH", "NONE"], var.auth_type)
    error_message = "auth_type must be one of: API_KEY, BASIC, OAUTH, NONE."
  }
}

variable "api_key" {
  description = "Configuration for API_KEY auth"
  type = object({
    key   = string
    value = string
  })
  default   = null
  sensitive = true
}

variable "basic_auth" {
  description = "Configuration for BASIC auth"
  type = object({
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "oauth" {
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
