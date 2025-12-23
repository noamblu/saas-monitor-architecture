variable "bus_name" {
  description = "Name of the EventBridge Bus"
  type        = string
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "rules" {
  description = "Map of EventBridge rules to create on this bus"
  type = map(object({
    description   = optional(string)
    event_pattern = optional(string) # JSON string
    state         = optional(string, "ENABLED")
    targets = map(object({
      arn             = string
      role_arn        = optional(string)
      dead_letter_arn = optional(string)
      input           = optional(string)
      input_path      = optional(string)
    }))
  }))
  default = {}
}

variable "archive" {
  description = "Configuration for EventBridge Archive"
  type = object({
    name           = string
    description    = optional(string)
    retention_days = optional(number)
    event_pattern  = optional(string)
  })
  default = null
}

variable "log_config" {
  description = "Logging configuration for the EventBridge Bus"
  type = object({
    include_detail = string # FULL or NONE
    log_type       = string # ERROR, INFO, or TRACE (maps to level in bus config)
  })
  default = null
}
