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
  validation {
    condition     = contains(["API_KEY", "BASIC", "OAUTH", "NONE"], var.auth_config.mode)
    error_message = "auth_config.mode must be one of: API_KEY, BASIC, OAUTH, NONE."
  }
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}
