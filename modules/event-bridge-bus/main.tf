resource "aws_cloudwatch_event_bus" "this" {
  name = var.bus_name
  tags = var.tags

  dynamic "log_config" {
    for_each = var.log_config != null ? [var.log_config] : []
    content {
      include_detail = log_config.value.include_detail
      # Level mapping for safety, default to INFO if not specified or fallback
      # Valid values: OFF, ERROR, INFO, TRACE
      # We map user's log_type (LOG_TYPE) to valid levels for consistency
      # Assuming user provides "INFO" -> "INFO", "ERROR" -> "ERROR", "TRACE" -> "TRACE"
      # But aws_cloudwatch_log_delivery_source uses "INFO_LOGS" etc.
      # User passes simple string in log_type.
      level = log_config.value.log_type
    }
  }
}

resource "aws_cloudwatch_log_delivery_source" "this" {
  count = var.log_config != null ? 1 : 0

  name         = "EventBusSource-${var.bus_name}-${var.log_config.log_type}_LOGS"
  log_type     = "${var.log_config.log_type}_LOGS"
  resource_arn = aws_cloudwatch_event_bus.this.arn
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
