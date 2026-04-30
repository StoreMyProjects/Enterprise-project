resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.name}-flow-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_flow_log" "this" {
  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}

# resource "aws_s3_bucket_versioning" "this" {
#   bucket = aws_s3_bucket.flow_logs.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.flow_logs.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "flow_logs_policy" {
  bucket = aws_s3_bucket.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AWSLogDeliveryWrite",
        Effect: "Allow",
        Principal: {
          Service: "delivery.logs.amazonaws.com"
        },
        Action: "s3:PutObject",
        Resource: "${aws_s3_bucket.flow_logs.arn}/*",
        Condition: {
          StringEquals: {
            "aws:SourceAccount": data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid: "AWSLogDeliveryAclCheck",
        Effect: "Allow",
        Principal: {
          Service: "delivery.logs.amazonaws.com"
        },
        Action: "s3:GetBucketAcl",
        Resource: aws_s3_bucket.flow_logs.arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}