variable "name" {
  description = "Name of the schedule"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression (e.g., rate(5 minutes))"
  type        = string
}

variable "target_arn" {
  description = "ARN of the target"
  type        = string
}

variable "target_role_arn" {
  description = "IAM Role ARN for the target"
  type        = string
}

variable "input" {
  description = "JSON input for the target"
  type        = string
  default     = "{}"
}
