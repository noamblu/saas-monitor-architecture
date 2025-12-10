resource "aws_cloudwatch_event_bus" "this" {
  name = var.bus_name
  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name           = each.key
  description    = each.value.description
  event_bus_name = aws_cloudwatch_event_bus.this.name
  event_pattern  = each.value.event_pattern
  state          = each.value.state
  tags           = var.tags
}

locals {
  # Flatten targets for resource creation
  targets = flatten([
    for rule_key, rule in var.rules : [
      for target_key, target in rule.targets : {
        rule_key        = rule_key
        target_key      = target_key
        arn             = target.arn
        role_arn        = target.role_arn
        dead_letter_arn = target.dead_letter_arn
        input           = target.input
        input_path      = target.input_path
      }
    ]
  ])
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = {
    for t in local.targets : "${t.rule_key}-${t.target_key}" => t
  }

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_key].name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  target_id      = each.value.target_key
  arn            = each.value.arn
  role_arn       = each.value.role_arn
  input          = each.value.input
  input_path     = each.value.input_path

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_arn != null ? [1] : []
    content {
      arn = each.value.dead_letter_arn
    }
  }
}

resource "aws_cloudwatch_event_archive" "this" {
  count = var.archive != null ? 1 : 0

  name             = var.archive.name
  description      = var.archive.description
  event_source_arn = aws_cloudwatch_event_bus.this.arn
  retention_days   = var.archive.retention_days
  event_pattern    = var.archive.event_pattern
}

# --- Logging Configuration ---

resource "aws_cloudwatch_log_group" "events" {
  count = var.enable_logging ? 1 : 0

  name              = var.log_group_name
  retention_in_days = 30 # Default to 30 days
  tags              = var.tags
}

resource "aws_cloudwatch_event_rule" "log_all" {
  count = var.enable_logging ? 1 : 0

  name           = "${var.bus_name}-log-all-events"
  description    = "Capture all events for logging"
  event_bus_name = aws_cloudwatch_event_bus.this.name
  state          = "ENABLED"

  event_pattern = jsonencode({
    source = [{ "prefix" : "" }] # Match all events
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "log_target" {
  count = var.enable_logging ? 1 : 0

  rule           = aws_cloudwatch_event_rule.log_all[0].name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  arn            = aws_cloudwatch_log_group.events[0].arn
}
