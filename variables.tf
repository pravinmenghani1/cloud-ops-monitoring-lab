variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "docker-nginx-instance"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for storing SSM command outputs"
  type        = string
  default     = "ssm-docker-install-logs"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP for better security
}
variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "Development"
}
