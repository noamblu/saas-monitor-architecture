# --- Modules ---

module "security_group" {
  source = "./modules/security-group"
  name   = "${var.saas_name}-lambda-sg"
  vpc_id = data.aws_vpc.selected.id

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "api_destination" {
  source              = "./modules/api-destination"
  name                = var.api_destination_name != null ? var.api_destination_name : var.saas_name
  invocation_endpoint = var.target_url
  auth_config         = var.auth_config
}

module "event_bus" {
  source   = "./modules/event-bridge-bus"
  bus_name = "custom-${var.saas_name}-event-bus"

  archive = {
    name           = "${var.saas_name}-event-archive"
    description    = "Archive for ${var.saas_name} events"
    retention_days = 10
    event_pattern = jsonencode({
      source = ["saas.${var.saas_name}"]
    })
  }

  rules = {
    "${var.saas_name}-forward-to-ops" = {
      description = "Forward SaaS health check events to central Ops bus"
      event_pattern = jsonencode({
        source      = ["saas.${var.saas_name}"]
        detail-type = ["SaaSHealthCheckResult"]
      })
      targets = {
        "ops-target" = {
          arn      = data.aws_cloudwatch_event_bus.ops_main_bus.arn
          role_arn = aws_iam_role.event_bus_invoke_role.arn
        }
      }
    }
  }
}

# IAM Role for Event Bus to invoke target (kept here as it's specific glue, or could be in a generic IAM module)
resource "aws_iam_role" "event_bus_invoke_role" {
  name = "${var.saas_name}-eb-invoke-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "event_bus_invoke_policy" {
  name = "${var.saas_name}-eb-invoke-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "events:PutEvents"
      Resource = data.aws_cloudwatch_event_bus.ops_main_bus.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "event_bus_invoke_attach" {
  role       = aws_iam_role.event_bus_invoke_role.name
  policy_arn = aws_iam_policy.event_bus_invoke_policy.arn
}

module "schema_registry" {
  source        = "./modules/schema-registry"
  registry_name = "${var.saas_name}-registry"
  description   = "Registry for ${var.saas_name} events"

  schemas = {
    "saas-${var.saas_name}-event-schema" = {
      description = "Schema for ${var.saas_name} health check events"
      type        = "JSONSchemaDraft4"
      content = jsonencode({
        "$schema" = "http://json-schema.org/draft-04/schema#"
        "type"    = "object"
        "properties" = {
          "saasName"    = { "type" = "string" }
          "status"      = { "type" = "string" }
          "latencyMs"   = { "type" = "number" }
          "checkedAt"   = { "type" = "string", "format" = "date-time" }
          "rawResponse" = { "type" = "object" }
        }
        "required" = ["saasName", "status", "checkedAt"]
      })
    }
  }
}

module "saas_poller_lambda" {
  source = "./modules/lambda"
  name   = "${var.saas_name}-saas-poller"

  source_config = {
    type = "dir"
    path = "${path.module}/src/saas_poller"
  }

  handler = "saas_poller.handler"

  vpc_config = {
    subnet_ids         = data.aws_subnets.selected.ids
    security_group_ids = [module.security_group.id]
  }

  environment_variables = {
    API_DESTINATION_NAME = module.api_destination.name
    CONNECTION_NAME      = module.api_destination.connection_name
    EVENT_BUS_NAME       = module.event_bus.bus_name
    SAAS_NAME            = var.saas_name
    AUTH_SECRET          = var.auth_config.mode == "API_KEY" ? var.auth_config.api_key.value : (var.auth_config.mode == "BASIC" ? var.auth_config.basic.password : (var.auth_config.mode == "OAUTH" ? var.auth_config.oauth.client_parameters.client_secret : ""))
  }

  additional_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["events:DescribeApiDestination", "events:DescribeConnection"]
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = ["events:PutEvents"]
          Resource = module.event_bus.bus_arn
        },
        {
          Effect   = "Allow"
          Action   = ["cloudwatch:PutMetricData"]
          Resource = "*"
        }
      ]
    })
  ]
}

# IAM Role for Scheduler (glue logic)
resource "aws_iam_role" "scheduler_role" {
  name = "${var.saas_name}-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "scheduler_policy" {
  name = "${var.saas_name}-scheduler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = module.saas_poller_lambda.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

module "monitor_schedule" {
  source              = "./modules/scheduler"
  name                = "${var.saas_name}-schedule"
  schedule_expression = "rate(5 minutes)"

  target_config = {
    arn      = module.saas_poller_lambda.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
