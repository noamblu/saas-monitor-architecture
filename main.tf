# --- IAM Roles (Custom for Scheduler and Pipe) ---
# We keep these here as they are specific glue logic, or we could make a module for them.
# For simplicity, we'll define them here but use the modules for the resources.

# --- IAM Roles ---

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

# --- VPC Security Group ---

# --- VPC Security Group ---

resource "aws_security_group" "lambda_sg" {
  name        = "${var.saas_name}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Modules ---

module "saas_poller_lambda" {
  source     = "./modules/lambda"
  name       = "${var.saas_name}-saas-poller"
  source_dir = "${path.module}/src/saas_poller"
  handler    = "saas_poller.handler"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.lambda_sg.id]

  environment_variables = {
    API_DESTINATION_NAME = module.api_destination.name
    CONNECTION_NAME      = module.api_destination.connection_name
    EVENT_BUS_NAME       = var.event_bus_name
    AUTH_SECRET          = var.auth_type == "API_KEY" ? var.api_key_config.value : (var.auth_type == "BASIC" ? var.basic_auth_config.password : (var.auth_type == "OAUTH" ? var.oauth_config.client_parameters.client_secret : ""))
  }

  additional_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["events:DescribeApiDestination", "events:DescribeConnection"]
          Resource = "*" # Describe actions often require wildcard or specific ARN construction
        },
        {
          Effect   = "Allow"
          Action   = ["events:PutEvents"]
          Resource = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:event-bus/${var.event_bus_name}"
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

module "monitor_schedule" {
  source              = "./modules/scheduler"
  name                = "${var.saas_name}-schedule"
  schedule_expression = "rate(5 minutes)"
  target_arn          = module.saas_poller_lambda.arn
  target_role_arn     = aws_iam_role.scheduler_role.arn
  input               = jsonencode({}) # No specific input needed for fetcher, or could pass overrides
}

module "api_destination" {
  source              = "./modules/api-destination"
  name                = var.saas_name
  invocation_endpoint = module.mock_saas_lambda.function_url

  auth_type  = var.auth_type
  api_key    = var.api_key_config
  basic_auth = var.basic_auth_config
  oauth      = var.oauth_config
}

module "mock_saas_lambda" {
  source      = "./modules/lambda"
  name        = "${var.saas_name}-mock"
  source_file = "${path.module}/src/mock_saas/mock_saas.py"
  handler     = "mock_saas.handler"
  create_url  = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.lambda_sg.id]
}

data "aws_caller_identity" "current" {}
