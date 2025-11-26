resource "aws_pipes_pipe" "this" {
  name     = var.name
  role_arn = var.role_arn
  source   = var.source_arn

  source_parameters {
    sqs_queue_parameters {
      batch_size = 1
    }
  }

  enrichment = var.enrichment_arn
  target     = var.target_arn
}
