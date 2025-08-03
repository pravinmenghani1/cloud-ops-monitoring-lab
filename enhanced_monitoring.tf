# Enhanced CloudWatch Alarms and Monitoring

# Application-level CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "nginx_error_rate" {
  alarm_name          = "docker-nginx-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"  # Reduced for faster triggering
  metric_name         = "ErrorRate"
  namespace           = "AWS/ApplicationELB"
  period              = "60"   # Reduced period
  statistic           = "Average"
  threshold           = "2"    # Reduced threshold
  alarm_description   = "This metric monitors nginx error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-high-error-rate"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "nginx_response_time" {
  alarm_name          = "docker-nginx-slow-response"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "This metric monitors nginx response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-slow-response"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "docker-nginx-instance-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 instance status check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-instance-status-check"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "system_status_check" {
  alarm_name          = "docker-nginx-system-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 system status check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-system-status-check"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "network_high_in" {
  alarm_name          = "docker-nginx-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000"  # 100MB
  alarm_description   = "This metric monitors high network input"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-high-network-in"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "docker_container_stopped" {
  alarm_name          = "docker-nginx-container-stopped"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "processes_running"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"  # Minimum expected running processes
  alarm_description   = "This metric monitors if critical processes are running"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-container-stopped"
    Environment = var.environment
  }
}

# CloudWatch Composite Alarms
resource "aws_cloudwatch_composite_alarm" "application_health" {
  alarm_name        = "docker-nginx-application-health"
  alarm_description = "Composite alarm for overall application health"
  
  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.high_cpu.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.high_memory.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.disk_space.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.instance_status_check.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.system_status_check.alarm_name})"
  ])

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "docker-nginx-application-health"
    Environment = var.environment
  }
}

# CloudWatch Synthetics for User Journey Monitoring
resource "aws_synthetics_canary" "nginx_health_check" {
  name                 = "nginx-health-check-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_artifacts.bucket}/canary-artifacts"
  execution_role_arn   = aws_iam_role.synthetics_role.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics_canary.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds    = 60
    memory_in_mb         = 960
    active_tracing       = true
  }

  success_retention_period = 2
  failure_retention_period = 14

  tags = {
    Name        = "nginx-health-check-canary"
    Environment = var.environment
  }
}

# S3 bucket for Synthetics artifacts
resource "aws_s3_bucket" "synthetics_artifacts" {
  bucket = "nginx-synthetics-artifacts-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "nginx-synthetics-artifacts"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "synthetics_artifacts_pab" {
  bucket = aws_s3_bucket.synthetics_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Synthetics
resource "aws_iam_role" "synthetics_role" {
  name = "CloudWatchSyntheticsRole"

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

  tags = {
    Name        = "CloudWatchSyntheticsRole"
    Environment = var.environment
  }
}

# Custom policy for Synthetics instead of managed policy
resource "aws_iam_role_policy" "synthetics_execution_policy" {
  name = "SyntheticsExecutionPolicy"
  role = aws_iam_role.synthetics_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "synthetics_s3_policy" {
  name = "SyntheticsS3Policy"
  role = aws_iam_role.synthetics_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.synthetics_artifacts.arn,
          "${aws_s3_bucket.synthetics_artifacts.arn}/*"
        ]
      }
    ]
  })
}

# Enhanced CloudWatch Insights Queries for User Journey Analysis
resource "aws_cloudwatch_query_definition" "user_journey_analysis" {
  name = "nginx-user-journey-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /nginx-access/
| parse @message /(?<ip>\d+\.\d+\.\d+\.\d+) - - \[(?<timestamp>[^\]]+)\] "(?<method>\w+) (?<path>[^"]*)" (?<status>\d+) (?<size>\d+) "(?<referer>[^"]*)" "(?<user_agent>[^"]*)" "[^"]*" rt=(?<response_time>[\d\.]+)/
| stats count() as page_views, avg(response_time) as avg_response_time by path
| sort page_views desc
| limit 20
EOF
}

resource "aws_cloudwatch_query_definition" "user_session_analysis" {
  name = "nginx-user-session-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /nginx-access/
| parse @message /(?<ip>\d+\.\d+\.\d+\.\d+) - - \[(?<timestamp>[^\]]+)\] "(?<method>\w+) (?<path>[^"]*)" (?<status>\d+) (?<size>\d+) "(?<referer>[^"]*)" "(?<user_agent>[^"]*)" "[^"]*" rt=(?<response_time>[\d\.]+)/
| stats count() as requests, min(@timestamp) as session_start, max(@timestamp) as session_end by ip
| sort requests desc
| limit 50
EOF
}

resource "aws_cloudwatch_query_definition" "request_tracing_analysis" {
  name = "nginx-request-tracing-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /nginx-access/
| parse @message /(?<ip>\d+\.\d+\.\d+\.\d+) - - \[(?<timestamp>[^\]]+)\] "(?<method>\w+) (?<path>[^"]*)" (?<status>\d+) (?<size>\d+) "(?<referer>[^"]*)" "(?<user_agent>[^"]*)" "[^"]*" rt=(?<response_time>[\d\.]+)/
| filter response_time > 1.0
| stats count() as slow_requests, avg(response_time) as avg_slow_response_time, max(response_time) as max_response_time by path, status
| sort avg_slow_response_time desc
EOF
}

resource "aws_cloudwatch_query_definition" "system_health_analysis" {
  name = "nginx-system-health-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /WARN/ or @message like /CRITICAL/
| stats count() as error_count by bin(5m)
| sort @timestamp desc
EOF
}

# Custom CloudWatch Metrics for Application Monitoring
resource "aws_cloudwatch_log_metric_filter" "nginx_error_rate" {
  name           = "nginx-error-rate"
  log_group_name = aws_cloudwatch_log_group.docker_nginx_logs.name
  pattern        = "[timestamp, request_id, ip, method, path, status=5*, ...]"

  metric_transformation {
    name      = "NginxErrorRate"
    namespace = "Custom/Nginx"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_response_time" {
  name           = "nginx-response-time"
  log_group_name = aws_cloudwatch_log_group.docker_nginx_logs.name
  pattern        = "[timestamp, request_id, ip, method, path, status, size, referer, user_agent, xff, rt_label=\"rt=\", response_time]"

  metric_transformation {
    name      = "NginxResponseTime"
    namespace = "Custom/Nginx"
    value     = "$response_time"
  }
}

resource "aws_cloudwatch_log_metric_filter" "nginx_request_count" {
  name           = "nginx-request-count"
  log_group_name = aws_cloudwatch_log_group.docker_nginx_logs.name
  pattern        = "[timestamp, request_id, ip, method, path, status, ...]"

  metric_transformation {
    name      = "NginxRequestCount"
    namespace = "Custom/Nginx"
    value     = "1"
  }
}

# CloudWatch Alarms for Custom Metrics
resource "aws_cloudwatch_metric_alarm" "custom_nginx_error_rate" {
  alarm_name          = "custom-nginx-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"  # Reduced for faster triggering
  metric_name         = "NginxErrorRate"
  namespace           = "Custom/Nginx"
  period              = "60"   # Reduced period
  statistic           = "Sum"
  threshold           = "3"    # Reduced threshold
  alarm_description   = "This metric monitors custom nginx error rate from logs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "custom-nginx-high-error-rate"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "custom_nginx_response_time" {
  alarm_name          = "custom-nginx-slow-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"  # Reduced for faster triggering
  metric_name         = "NginxResponseTime"
  namespace           = "Custom/Nginx"
  period              = "60"   # Reduced period
  statistic           = "Average"
  threshold           = "1.0"  # Reduced threshold for easier demo
  alarm_description   = "This metric monitors custom nginx response time from logs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name        = "custom-nginx-slow-response-time"
    Environment = var.environment
  }
}

# SNS Topic Subscription for Email Notifications
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "pravinmenghani@gmail.com"  # Your email for notifications
}

# CloudWatch Dashboard Enhancement
resource "aws_cloudwatch_dashboard" "enhanced_monitoring_dashboard" {
  dashboard_name = "Enhanced-Docker-Nginx-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Custom/Nginx", "NginxRequestCount"],
            [".", "NginxErrorRate"],
            [".", "NginxResponseTime"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Custom Nginx Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudWatchSynthetics", "SuccessPercent", "CanaryName", aws_synthetics_canary.nginx_health_check.name],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Synthetics Health Check"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/ec2/docker-nginx' | fields @timestamp, @message | filter @message like /nginx-access/ | parse @message /(?<ip>\\d+\\.\\d+\\.\\d+\\.\\d+) - - \\[(?<timestamp>[^\\]]+)\\] \"(?<method>\\w+) (?<path>[^\"]*) HTTP\\/[\\d\\.]+\" (?<status>\\d+) (?<size>\\d+)/ | stats count() by path | sort count desc | limit 10"
          region  = var.aws_region
          title   = "Top Requested Pages"
        }
      }
    ]
  })
}
