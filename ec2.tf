# EC2 Instance
resource "aws_instance" "docker_nginx" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.docker_nginx_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data_enhanced.sh", {
    s3_bucket = aws_s3_bucket.ssm_output_bucket.bucket
  }))

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    SSMManaged  = "true"
    DockerHost  = "true"
  }

  # Ensure the instance is created after IAM role is ready
  depends_on = [
    aws_iam_role_policy_attachment.ssm_managed_instance_core,
    aws_iam_role_policy_attachment.cloudwatch_agent_server_policy,
    aws_iam_role_policy_attachment.s3_ssm_output_attachment,
    aws_iam_role_policy_attachment.xray_attachment,
    aws_iam_role_policy_attachment.enhanced_cloudwatch_attachment
  ]
}
