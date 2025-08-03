# CloudWatch Dashboard for EC2 Monitoring
resource "aws_cloudwatch_dashboard" "docker_nginx_dashboard" {
  dashboard_name = "Docker-Nginx-EC2-Dashboard"

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
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.docker_nginx.id],
            ["CWAgent", "cpu_usage_idle", "InstanceId", aws_instance.docker_nginx.id],
            [".", "cpu_usage_iowait", ".", "."],
            [".", "cpu_usage_user", ".", "."],
            [".", "cpu_usage_system", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Metrics"
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
            ["CWAgent", "mem_used_percent", "InstanceId", aws_instance.docker_nginx.id],
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", aws_instance.docker_nginx.id],
            [".", "StatusCheckFailed_Instance", ".", "."],
            [".", "StatusCheckFailed_System", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Memory Usage & Status Checks"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.docker_nginx.id, "device", "/dev/xvda1", "fstype", "xfs", "path", "/"],
            [".", "diskio_io_time", "InstanceId", aws_instance.docker_nginx.id, "name", "xvda"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Disk Usage & I/O"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.docker_nginx.id],
            [".", "NetworkOut", ".", "."],
            [".", "NetworkPacketsIn", ".", "."],
            [".", "NetworkPacketsOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Network Throughput"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/ec2/docker-nginx' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent EC2 Logs"
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "docker-nginx-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-high-cpu"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "docker-nginx-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ec2 memory utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-high-memory"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_space" {
  alarm_name          = "docker-nginx-disk-space"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors ec2 disk utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.docker_nginx.id
  }

  tags = {
    Name        = "docker-nginx-disk-space"
    Environment = var.environment
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "docker-nginx-alerts"

  tags = {
    Name        = "docker-nginx-alerts"
    Environment = var.environment
  }
}

# CloudWatch RUM App Monitor
resource "aws_rum_app_monitor" "nginx_rum" {
  name   = "nginx-app-monitor"
  domain = "54.80.210.131"  # Your EC2 public IP

  app_monitor_configuration {
    allow_cookies      = true
    enable_xray        = true
    session_sample_rate = 0.1
    telemetries        = ["errors", "performance", "http"]
    
    favorite_pages = ["/", "/health"]
  }

  custom_events {
    status = "ENABLED"
  }

  tags = {
    Name        = "nginx-rum-monitor"
    Environment = var.environment
  }
}

# X-Ray Service Map
resource "aws_xray_sampling_rule" "nginx_sampling" {
  rule_name      = "nginx-sampling-rule"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_name   = "nginx-app"
  service_type   = "*"
  resource_arn   = "*"

  tags = {
    Name        = "nginx-sampling-rule"
    Environment = var.environment
  }
}

# CloudWatch Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "nginx-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| stats count() by bin(5m)
| sort @timestamp desc
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "nginx-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.docker_nginx_logs.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /response_time/
| parse @message /response_time: (?<response_time>\d+)/
| stats avg(response_time), max(response_time), min(response_time) by bin(5m)
| sort @timestamp desc
EOF
}
