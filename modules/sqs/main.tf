resource "aws_sqs_queue" "this" {
  name = var.name
}

resource "aws_sqs_queue_policy" "this" {
  count     = var.policy != null ? 1 : 0
  queue_url = aws_sqs_queue.this.id
  policy    = var.policy
}
