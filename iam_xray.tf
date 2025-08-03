# Additional IAM policy for X-Ray tracing
resource "aws_iam_policy" "xray_policy" {
  name        = "EC2-XRay-Policy"
  description = "Policy to allow EC2 instance to send traces to X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "EC2-XRay-Policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "xray_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.xray_policy.arn
}

# Additional IAM policy for enhanced CloudWatch metrics
resource "aws_iam_policy" "enhanced_cloudwatch_policy" {
  name        = "EC2-Enhanced-CloudWatch-Policy"
  description = "Enhanced policy for CloudWatch metrics and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "EC2-Enhanced-CloudWatch-Policy"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_cloudwatch_attachment" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.enhanced_cloudwatch_policy.arn
}
