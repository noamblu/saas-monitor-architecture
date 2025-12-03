resource "aws_schemas_registry" "this" {
  name        = var.registry_name
  description = var.description
  tags        = var.tags
}

resource "aws_schemas_schema" "this" {
  for_each = var.schemas

  name          = each.key
  registry_name = aws_schemas_registry.this.name
  type          = each.value.type
  description   = each.value.description
  content       = each.value.content
  tags          = var.tags
}
