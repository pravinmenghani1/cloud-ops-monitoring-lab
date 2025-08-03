output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.docker_nginx.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.docker_nginx.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.docker_nginx.public_dns
}

output "nginx_url" {
  description = "URL to access the Nginx application"
  value       = "http://${aws_instance.docker_nginx.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing SSM command outputs"
  value       = aws_s3_bucket.ssm_output_bucket.bucket
}

output "ssm_docker_install_document" {
  description = "Name of the SSM document for Docker installation"
  value       = aws_ssm_document.install_docker.name
}

output "ssm_nginx_deploy_document" {
  description = "Name of the SSM document for Nginx deployment"
  value       = aws_ssm_document.deploy_nginx.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for instance logs"
  value       = aws_cloudwatch_log_group.docker_nginx_logs.name
}
# New monitoring outputs
output "cloudwatch_dashboard_url" {
  description = "URL to access the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.docker_nginx_dashboard.dashboard_name}"
}

output "rum_app_monitor_id" {
  description = "CloudWatch RUM App Monitor ID"
  value       = aws_rum_app_monitor.nginx_rum.app_monitor_id
}

output "rum_identity_pool_id" {
  description = "Cognito Identity Pool ID for RUM"
  value       = aws_cognito_identity_pool.rum_identity_pool.id
}

output "xray_console_url" {
  description = "URL to access X-Ray console"
  value       = "https://console.aws.amazon.com/xray/home?region=${var.aws_region}#/service-map"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "rum_assets_bucket" {
  description = "S3 bucket for RUM assets"
  value       = aws_s3_bucket.rum_assets.bucket
}

output "monitoring_endpoints" {
  description = "Monitoring endpoints for the application"
  value = {
    health_check  = "http://${aws_instance.docker_nginx.public_ip}/health"
    nginx_status  = "http://${aws_instance.docker_nginx.public_ip}/nginx_status"
    rum_dashboard = "https://console.aws.amazon.com/rum/home?region=${var.aws_region}#/application/${aws_rum_app_monitor.nginx_rum.name}"
  }
}
