variable "bus_name" {
  description = "Name of the Event Bus"
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  type        = string
  default     = null
}

variable "rules" {
  description = "Map of rules and their targets"
  type = map(object({
    description   = string
    event_pattern = string
    targets = list(object({
      arn      = string
      role_arn = optional(string)
    }))
  }))
  default = {}
}
