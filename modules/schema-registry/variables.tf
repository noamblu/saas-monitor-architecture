variable "registry_name" {
  description = "Name of the Schema Registry"
  type        = string
}

variable "description" {
  description = "Description of the Schema Registry"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "schemas" {
  description = "Map of schemas to create in this registry"
  type = map(object({
    description = optional(string)
    type        = string # e.g. JSONSchemaDraft4
    content     = string # JSON string
  }))
  default = {}
}
