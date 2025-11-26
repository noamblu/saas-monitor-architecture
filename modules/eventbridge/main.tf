resource "aws_cloudwatch_event_bus" "this" {
  name = var.bus_name
}

resource "aws_cloudwatch_log_group" "this" {
  count             = var.log_group_name != null ? 1 : 0
  name              = var.log_group_name
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = var.rules

  name           = each.key
  description    = each.value.description
  event_bus_name = aws_cloudwatch_event_bus.this.name
  event_pattern  = each.value.event_pattern
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = {
    for pair in flatten([
      for rule_key, rule in var.rules : [
        for idx, target in rule.targets : {
          rule_key = rule_key
          idx      = idx
          target   = target
        }
      ]
    ]) : "${pair.rule_key}-${pair.idx}" => pair
  }

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_key].name
  event_bus_name = aws_cloudwatch_event_bus.this.name
  arn            = each.value.target.arn
  role_arn       = each.value.target.role_arn
}

# --- Resource Policy for Logs ---
data "aws_iam_policy_document" "cw_log_policy" {
  count = var.log_group_name != null ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.this[0].arn}:*"]

    principals {
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  count           = var.log_group_name != null ? 1 : 0
  policy_name     = "${var.bus_name}-log-policy"
  policy_document = data.aws_iam_policy_document.cw_log_policy[0].json
}
