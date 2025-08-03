# CloudWatch Log Group for EC2 logs
resource "aws_cloudwatch_log_group" "docker_nginx_logs" {
  name              = "/aws/ec2/docker-nginx"
  retention_in_days = 7

  tags = {
    Name = "docker-nginx-logs"
  }
}

# SSM Document for Docker installation
resource "aws_ssm_document" "install_docker" {
  name          = "InstallDocker"
  document_type = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Install Docker on Amazon Linux 2023
parameters:
  s3BucketName:
    type: String
    description: S3 bucket to store command output
    default: "${aws_s3_bucket.ssm_output_bucket.bucket}"
mainSteps:
- action: aws:runShellScript
  name: installDocker
  inputs:
    timeoutSeconds: '300'
    runCommand:
    - echo "Starting Docker installation..."
    - yum update -y
    - yum install -y docker
    - systemctl start docker
    - systemctl enable docker
    - usermod -a -G docker ec2-user
    - docker --version
    - echo "Docker installation completed successfully"
    - echo "Docker service status:"
    - systemctl status docker --no-pager
DOC

  tags = {
    Name = "InstallDocker"
  }
}

# SSM Document for Nginx container deployment
resource "aws_ssm_document" "deploy_nginx" {
  name          = "DeployNginxContainer"
  document_type = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Deploy Nginx container using Docker
parameters:
  s3BucketName:
    type: String
    description: S3 bucket to store command output
    default: "${aws_s3_bucket.ssm_output_bucket.bucket}"
mainSteps:
- action: aws:runShellScript
  name: deployNginx
  inputs:
    timeoutSeconds: '300'
    runCommand:
    - echo "Starting Nginx container deployment..."
    - docker pull nginx:latest
    - docker stop nginx-container || true
    - docker rm nginx-container || true
    - docker run -d --name nginx-container -p 80:80 nginx:latest
    - echo "Nginx container deployed successfully"
    - echo "Container status:"
    - docker ps
    - echo "Testing nginx response:"
    - sleep 5
    - curl -I http://localhost:80 || echo "Nginx not yet ready"
DOC

  tags = {
    Name = "DeployNginxContainer"
  }
}

# Execute Docker installation via SSM
resource "aws_ssm_association" "install_docker" {
  name = aws_ssm_document.install_docker.name

  targets {
    key    = "tag:SSMManaged"
    values = ["true"]
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_output_bucket.bucket
    s3_key_prefix  = "docker-installation/"
  }

  depends_on = [aws_instance.docker_nginx]
}

# Execute Nginx deployment via SSM (depends on Docker installation)
resource "aws_ssm_association" "deploy_nginx" {
  name = aws_ssm_document.deploy_nginx.name

  targets {
    key    = "tag:DockerHost"
    values = ["true"]
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_output_bucket.bucket
    s3_key_prefix  = "nginx-deployment/"
  }

  depends_on = [
    aws_ssm_association.install_docker,
    aws_instance.docker_nginx
  ]

  # Add a delay to ensure Docker is fully installed
  schedule_expression = "rate(30 minutes)"
  max_concurrency    = "1"
  max_errors         = "0"
}
