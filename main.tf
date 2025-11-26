# --- IAM Roles (Custom for Scheduler and Pipe) ---
# We keep these here as they are specific glue logic, or we could make a module for them.
# For simplicity, we'll define them here but use the modules for the resources.

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
      Action   = "sqs:SendMessage"
      Resource = module.monitor_queue.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

resource "aws_iam_role" "pipe_role" {
  name = "${var.saas_name}-pipe-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "pipes.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "pipe_policy" {
  name = "${var.saas_name}-pipe-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = module.monitor_queue.arn
      },
      {
        Effect   = "Allow"
        Action   = "events:InvokeApiDestination"
        Resource = module.api_destination.arn
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = module.processor_lambda.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipe_attach" {
  role       = aws_iam_role.pipe_role.name
  policy_arn = aws_iam_policy.pipe_policy.arn
}

# --- Modules ---

module "monitor_queue" {
  source = "./modules/sqs"
  name   = "${var.saas_name}-queue"
}

module "monitor_schedule" {
  source              = "./modules/scheduler"
  name                = "${var.saas_name}-schedule"
  schedule_expression = "rate(5 minutes)"
  target_arn          = module.monitor_queue.arn
  target_role_arn     = aws_iam_role.scheduler_role.arn
  input               = jsonencode({ message = "Triggering SaaS check" })
}

module "mock_saas_lambda" {
  source      = "./modules/lambda"
  name        = "${var.saas_name}-mock-api"
  source_file = "${path.module}/src/mock_saas/mock_saas.py"
  handler     = "mock_saas.lambda_handler"
  create_url  = true
}

module "processor_lambda" {
  source = "./modules/lambda"
  name   = "${var.saas_name}-processor"
  # Use provided path or default to local src/processor/processor.py
  source_file = var.processor_source_path != null ? var.processor_source_path : "${path.module}/src/processor/processor.py"
  handler     = "processor.lambda_handler"

  environment_variables = {
    SAAS_NAME      = var.saas_name
    EVENT_BUS_NAME = var.event_bus_name
  }

  additional_policies = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
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

module "api_destination" {
  source              = "./modules/api-destination"
  name                = var.saas_name
  invocation_endpoint = module.mock_saas_lambda.function_url

  auth_type  = var.auth_type
  api_key    = var.api_key_config
  basic_auth = var.basic_auth_config
  oauth      = var.oauth_config
}

module "monitor_pipe" {
  source         = "./modules/pipe"
  name           = "${var.saas_name}-pipe"
  role_arn       = aws_iam_role.pipe_role.arn
  source_arn     = module.monitor_queue.arn
  enrichment_arn = module.api_destination.arn
  target_arn     = module.processor_lambda.arn
}

data "aws_caller_identity" "current" {}
