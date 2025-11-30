variable "name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_file" {
  description = "Path to the source file (mutually exclusive with source_dir)"
  type        = string
  default     = null
}

variable "source_dir" {
  description = "Path to the source directory (mutually exclusive with source_file)"
  type        = string
  default     = null
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

variable "subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "use_vpc" {
  description = "Enable/disable VPC attachment"
  type        = bool
  default     = true
}
