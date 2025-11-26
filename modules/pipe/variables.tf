variable "name" {
  description = "Name of the pipe"
  type        = string
}

variable "source_arn" {
  description = "ARN of the source"
  type        = string
}

variable "target_arn" {
  description = "ARN of the target"
  type        = string
}

variable "enrichment_arn" {
  description = "ARN of the enrichment"
  type        = string
  default     = null
}

variable "role_arn" {
  description = "IAM Role ARN for the pipe"
  type        = string
}
