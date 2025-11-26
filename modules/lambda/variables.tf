variable "name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_file" {
  description = "Path to the source file"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "create_url" {
  description = "Whether to create a Function URL"
  type        = bool
  default     = false
}

variable "additional_policies" {
  description = "List of IAM policy JSON strings to attach"
  type        = list(string)
  default     = []
}
