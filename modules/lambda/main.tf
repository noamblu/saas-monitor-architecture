data "archive_file" "zip" {
  type        = "zip"
  source_file = var.source_file
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.name}.zip"
}

resource "aws_iam_role" "this" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "additional" {
  count  = length(var.additional_policies) > 0 ? length(var.additional_policies) : 0
  name   = "${var.name}-policy-${count.index}"
  policy = var.additional_policies[count.index]
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.additional_policies) > 0 ? length(var.additional_policies) : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.additional[count.index].arn
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.zip.output_path
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = var.runtime

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function_url" "this" {
  count              = var.create_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"
}
