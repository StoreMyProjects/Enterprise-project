resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.name}-flow-logs"

  tags = local.common_tags
}

resource "aws_flow_log" "this" {
  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}