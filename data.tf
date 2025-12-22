data "aws_vpc" "selected" {}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:noam"
    values = ["1"]
  }
}

data "aws_cloudwatch_event_bus" "ops_main_bus" {
  name = var.ops_main_events_bus_name
}

data "aws_caller_identity" "current" {}

data "aws_lambda_layer_version" "dependencies" {
  layer_name = var.lambda_layer_name
}
