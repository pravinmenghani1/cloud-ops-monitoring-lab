# Cloud Operations Monitoring Lab
## Complete AWS Infrastructure with Automated Deployment, Monitoring & Alerting

This comprehensive hands-on lab demonstrates production-ready cloud infrastructure with automated EC2 deployment using Terraform & SSM, Docker containerization with Nginx, real-time monitoring with CloudWatch, email alerting via SNS, stress testing and failure simulation, plus complete observability and troubleshooting tools.

## What This Project Does

Imagine you want to host a website on the cloud. This project automates the entire process:
1. Creates a virtual server (EC2) in the cloud
2. Installs Docker (containerization platform) on that server
3. Deploys Nginx (web server) inside a Docker container
4. Sets up monitoring to watch your website's health
5. Configures alerts to notify you if something goes wrong
6. Provides logging to troubleshoot issues

## Architecture Overview - The Big Picture

Think of this infrastructure like building a house with smart home features:

### 🏠 **VPC (Virtual Private Cloud)** - Your Digital Property
- **What it is**: A private section of AWS cloud that belongs only to you
- **What it does**: Creates an isolated network environment where your resources live
- **Why it's important**: Just like your house needs a property boundary, your cloud resources need a secure, isolated network
- **How it works**: AWS creates a virtual network with its own IP address range (like 10.0.0.0/16), completely separate from other customers

### 🖥️ **EC2 Instance** - Your Virtual Computer
- **What it is**: A virtual server running Amazon Linux 2023 (t2.micro size)
- **What it does**: Acts as your computer in the cloud where applications run
- **Why it's important**: This is where your website actually lives and serves content to users
- **How it works**: AWS allocates CPU, memory, and storage resources and creates a virtual machine you can control
- **Size Details**: t2.micro provides 1 vCPU and 1GB RAM - perfect for small websites and testing

### 🔐 **IAM Role & Instance Profile** - Your Digital Identity Card
- **What it is**: A set of permissions that defines what your EC2 instance can do
- **What it does**: Allows your server to communicate with other AWS services securely
- **Why it's important**: Without proper permissions, your server can't access CloudWatch, SSM, or S3
- **How it works**: 
  - IAM Role contains policies (permission rules)
  - Instance Profile attaches the role to your EC2 instance
  - AWS automatically provides temporary credentials to your instance
  - Your instance can now make API calls to other AWS services

### 📋 **SSM (Systems Manager) Documents** - Your Automation Scripts
- **What it is**: Pre-written scripts that automate server management tasks
- **What it does**: Automatically installs Docker and deploys Nginx without manual intervention
- **Why it's important**: Eliminates human error and ensures consistent deployments
- **How it works**:
  - **InstallDocker Document**: Contains shell commands to install Docker Engine
  - **DeployNginxContainer Document**: Contains commands to pull and run Nginx container
  - SSM Agent (pre-installed on Amazon Linux) executes these documents
  - Commands run with root privileges on your EC2 instance

### 🪣 **S3 Bucket** - Your Digital Filing Cabinet
- **What it is**: Cloud storage that holds files and logs
- **What it does**: Stores output from SSM command executions for troubleshooting
- **Why it's important**: When automation runs, you need to see what happened (success/failure logs)
- **How it works**: 
  - Every SSM command execution creates log files
  - These logs are automatically uploaded to your S3 bucket
  - You can download and review them to understand what happened

### 📊 **CloudWatch** - Your Monitoring System
- **What it is**: AWS's monitoring and alerting service
- **What it does**: Watches your infrastructure and applications for problems
- **Why it's important**: You need to know immediately if your website goes down
- **How it works**:
  - **CloudWatch Agent**: Installed on EC2, collects system metrics (CPU, memory, disk)
  - **Log Groups**: Organize logs from different sources
  - **Metrics**: Numerical data points (CPU usage, memory usage, HTTP response times)
  - **Alarms**: Trigger when metrics cross thresholds you define

### 🚨 **SNS (Simple Notification Service)** - Your Alert System
- **What it is**: AWS's messaging service for sending notifications
- **What it does**: Sends email alerts when problems are detected
- **Why it's important**: You can't watch your website 24/7, but SNS can
- **How it works**:
  - Creates a "topic" (like a mailing list)
  - Subscribes your email address to the topic
  - CloudWatch alarms publish messages to the topic
  - SNS delivers messages to all subscribers

### 🔒 **Security Group** - Your Digital Firewall
- **What it is**: Virtual firewall rules that control network traffic
- **What it does**: Decides which internet traffic can reach your server
- **Why it's important**: Protects your server from unauthorized access
- **How it works**:
  - **Inbound Rules**: Control traffic coming TO your server
  - **Outbound Rules**: Control traffic going FROM your server
  - Rules specify: protocol (HTTP/HTTPS), port (80/443), and source IP ranges

### 🐳 **Docker** - Your Application Container Platform
- **What it is**: A platform that packages applications with their dependencies
- **What it does**: Ensures your application runs consistently anywhere
- **Why it's important**: Eliminates "it works on my machine" problems
- **How it works**:
  - **Docker Engine**: The runtime that manages containers
  - **Docker Images**: Templates for creating containers (like a blueprint)
  - **Docker Containers**: Running instances of images (like a house built from blueprint)

### 🌐 **Nginx** - Your Web Server
- **What it is**: High-performance web server software
- **What it does**: Serves web pages to users who visit your website
- **Why it's important**: Handles HTTP requests and delivers content efficiently
- **How it works**:
  - Listens on port 80 for HTTP requests
  - Serves static files (HTML, CSS, JavaScript, images)
  - Can proxy requests to other applications
  - Handles multiple concurrent connections efficiently

## Detailed Deployment Flow - What Happens Behind the Scenes

When you run `terraform apply`, here's the exact sequence of events:

### Phase 1: Infrastructure Creation (0-2 minutes)
1. **VPC Creation**: AWS creates your private network space
2. **Subnet Creation**: A public subnet is created within your VPC
3. **Internet Gateway**: Allows your resources to access the internet
4. **Route Table**: Defines how network traffic flows
5. **Security Group**: Firewall rules are established

### Phase 2: IAM and Permissions (2-3 minutes)
1. **IAM Role Creation**: AWS creates the role with necessary permissions
2. **Policy Attachment**: Policies for SSM, CloudWatch, and S3 are attached
3. **Instance Profile**: Links the IAM role to EC2 instances

### Phase 3: Storage and Monitoring Setup (3-4 minutes)
1. **S3 Bucket Creation**: Your log storage bucket is created
2. **SNS Topic Creation**: Alert system is established
3. **Email Subscription**: Your email (pravinmenghani@gmail.com) is subscribed
4. **CloudWatch Log Groups**: Log destinations are prepared

### Phase 4: EC2 Instance Launch (4-6 minutes)
1. **Instance Launch**: EC2 instance starts booting
2. **SSM Agent Initialization**: Agent registers with SSM service
3. **CloudWatch Agent Installation**: Monitoring agent is installed
4. **User Data Execution**: Initial setup scripts run

### Phase 5: Application Deployment (6-10 minutes)
1. **SSM Document Execution**: InstallDocker document runs
   - Downloads Docker packages
   - Installs Docker Engine
   - Starts Docker service
   - Adds ec2-user to docker group
2. **Container Deployment**: DeployNginxContainer document runs
   - Pulls nginx:latest image from Docker Hub
   - Stops any existing nginx container
   - Starts new nginx container on port 80
3. **Health Checks**: CloudWatch alarms become active

### Phase 6: Monitoring Activation (10+ minutes)
1. **Metric Collection**: CloudWatch starts receiving metrics
2. **Log Streaming**: Application logs flow to CloudWatch
3. **Alarm States**: Monitoring alarms transition to OK state

## Deep Dive: How Each Component Works

### SSM Document Execution Process
```bash
# What happens when InstallDocker runs:
sudo yum update -y                    # Updates system packages
sudo yum install -y docker            # Installs Docker Engine
sudo systemctl start docker           # Starts Docker service
sudo systemctl enable docker          # Enables Docker to start on boot
sudo usermod -a -G docker ec2-user    # Adds user to docker group
```

### Docker Container Lifecycle
```bash
# What happens when DeployNginxContainer runs:
docker pull nginx:latest              # Downloads nginx image
docker stop nginx-container || true   # Stops existing container
docker rm nginx-container || true     # Removes existing container
docker run -d --name nginx-container -p 80:80 nginx:latest  # Starts new container
```

### CloudWatch Monitoring Flow
1. **Metric Collection**: Every 5 minutes, CloudWatch Agent collects:
   - CPU utilization percentage
   - Memory usage percentage
   - Disk space utilization
   - Network in/out bytes
2. **Log Collection**: Real-time log streaming from:
   - Docker daemon logs
   - Nginx access logs
   - System logs
3. **Alarm Evaluation**: Every minute, CloudWatch checks if metrics exceed thresholds

### SNS Alert Mechanism
1. **Alarm Triggers**: When CPU > 80% for 2 consecutive periods
2. **Message Creation**: CloudWatch creates alert message with details
3. **Topic Publishing**: Message is sent to SNS topic
4. **Email Delivery**: SNS delivers email to pravinmenghani@gmail.com
5. **Confirmation**: Email includes alarm details, timestamp, and metric values

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)
3. Appropriate AWS permissions for EC2, IAM, SSM, S3, and CloudWatch

## Deployment Steps

1. **Clone and navigate to the directory**:
   ```bash
   cd /Users/pravinmenghani/Documents/mon-cfgmgmt
   ```

2. **Create terraform.tfvars file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Wait for deployment**: The process includes:
   - EC2 instance creation
   - CloudWatch agent installation
   - SSM document creation
   - Docker installation via SSM
   - Nginx container deployment via SSM

## Accessing the Application

After deployment completes (approximately 5-10 minutes):

1. Get the public IP from Terraform output:
   ```bash
   terraform output nginx_url
   ```

2. Access the Nginx application in your browser using the provided URL.

## Comprehensive Monitoring and Logging

### CloudWatch Metrics Available
- **CPU Utilization**: Percentage of CPU being used
- **Memory Utilization**: Percentage of RAM being used
- **Disk Space**: Available disk space on root volume
- **Network Traffic**: Bytes in/out through network interface
- **HTTP Response Codes**: 200, 404, 500 status codes from Nginx

### Log Groups and Their Purpose
- **`/aws/ec2/docker-nginx`**: Application and container logs
- **`/aws/ssm/command-execution`**: SSM command outputs and errors
- **`/var/log/messages`**: System-level logs from EC2 instance

### S3 Bucket Structure
```
your-s3-bucket/
├── ssm-outputs/
│   ├── install-docker/
│   │   ├── stdout.txt
│   │   └── stderr.txt
│   └── deploy-nginx/
│       ├── stdout.txt
│       └── stderr.txt
└── cloudwatch-logs/
    └── exported-logs/
```

### Alert Thresholds Configured
- **High CPU Usage**: Alert when CPU > 80% for 10 minutes
- **High Memory Usage**: Alert when Memory > 85% for 10 minutes
- **Disk Space Low**: Alert when disk usage > 90%
- **Container Down**: Alert when Nginx container stops running
- **HTTP Errors**: Alert when 5xx errors exceed 10 per minute

## Manual SSM Commands (Optional)

You can also run the SSM documents manually:

```bash
# Install Docker
aws ssm send-command \
  --document-name "InstallDocker" \
  --targets "Key=tag:SSMManaged,Values=true" \
  --output-s3-bucket-name <your-s3-bucket>

# Deploy Nginx
aws ssm send-command \
  --document-name "DeployNginxContainer" \
  --targets "Key=tag:DockerHost,Values=true" \
  --output-s3-bucket-name <your-s3-bucket>
```

## Live Demo: Stress Testing and Alert System

This section demonstrates how the monitoring system works when your application experiences high load or goes down.

### Scenario: Website Under Heavy Load

Let's simulate a real-world scenario where your website experiences a sudden spike in traffic:

#### Step 1: Generate CPU Load (Stress Test)
Connect to your EC2 instance and run a CPU stress test:

```bash
# Connect via SSM Session Manager (no SSH keys needed!)
aws ssm start-session --target <your-instance-id>

# Once connected, run CPU stress test
sudo yum install -y stress
stress --cpu 2 --timeout 600s  # Run for 10 minutes
```

#### Step 2: What Happens During the Stress Test

**Minute 1-2: Load Increases**
- CPU utilization jumps from ~5% to 95%
- CloudWatch Agent detects the spike
- Metrics are sent to CloudWatch every minute

**Minute 3-4: Threshold Breach**
- CPU stays above 80% for 2 consecutive data points
- CloudWatch alarm state changes from "OK" to "ALARM"
- SNS topic receives the alarm notification

**Minute 5: Email Alert Sent**
pravinmenghani@gmail.com receives an email like this:

```
Subject: ALARM: "HighCPUUtilization" in US East (N. Virginia)

You are receiving this email because your Amazon CloudWatch Alarm 
"HighCPUUtilization" in the US East (N. Virginia) region has entered 
the ALARM state, because "Threshold Crossed: 1 out of the last 1 
datapoints [95.2 (03/08/25 10:15:00)] was greater than the threshold (80.0)."

View this alarm in the AWS Management Console:
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:alarm/HighCPUUtilization

Alarm Details:
- Name: HighCPUUtilization
- Description: Triggers when CPU utilization exceeds 80%
- State Change: OK -> ALARM
- Reason: Threshold Crossed
- Timestamp: Sunday 03 August, 2025 10:15:00 UTC
- AWS Account: 123456789012
- Alarm Arn: arn:aws:cloudwatch:us-east-1:123456789012:alarm:HighCPUUtilization

Threshold:
- The alarm is now in ALARM state since the metric is GreaterThanThreshold 80.0
```

#### Step 3: Monitoring Dashboard View

While the stress test runs, you can observe:

**CloudWatch Console:**
- CPU metric graph shows spike to 95%
- Memory usage increases due to stress processes
- Network traffic may increase if users can't access the site

**Application Behavior:**
- Nginx response times increase
- Some requests may timeout
- Error rate might increase

#### Step 4: Recovery and Resolution

**When stress test ends:**
- CPU utilization drops back to normal (~5%)
- After 2 consecutive normal readings, alarm returns to "OK"
- Recovery email is sent to pravinmenghani@gmail.com

```
Subject: OK: "HighCPUUtilization" in US East (N. Virginia)

You are receiving this email because your Amazon CloudWatch Alarm 
"HighCPUUtilization" in the US East (N. Virginia) region has returned 
to the OK state, because "Threshold Crossed: 1 out of the last 1 
datapoints [8.5 (03/08/25 10:25:00)] was not greater than the threshold (80.0)."
```

### Scenario: Complete Application Failure

Let's simulate what happens when your application completely fails:

#### Step 1: Stop the Nginx Container
```bash
# Connect to EC2 instance
aws ssm start-session --target <your-instance-id>

# Stop the nginx container
docker stop nginx-container
```

#### Step 2: What Happens When App Goes Down

**Immediate Effects:**
- Website becomes inaccessible (HTTP 502/503 errors)
- Health check failures begin
- Error logs start appearing in CloudWatch

**Within 5 minutes:**
- CloudWatch detects container is down
- HTTP error rate alarm triggers
- Multiple alarms may fire simultaneously:
  - Container health check failure
  - HTTP 5xx error rate spike
  - Potentially low network traffic (no successful requests)

#### Step 3: Alert Email for Application Down
pravinmenghani@gmail.com receives:

```
Subject: ALARM: "NginxContainerDown" in US East (N. Virginia)

ALARM State: ALARM
Reason: Threshold Crossed: 1 out of the last 1 datapoints [0.0 (03/08/25 10:30:00)] 
was less than the threshold (1.0) for metric "ContainerRunning".

This means your Nginx container has stopped running and your website is down.

Immediate Actions Required:
1. Check container status: docker ps -a
2. Review container logs: docker logs nginx-container
3. Restart container: docker start nginx-container
4. Verify website accessibility

Time of Failure: Sunday 03 August, 2025 10:30:00 UTC
```

#### Step 4: Troubleshooting with Available Tools

**Check S3 Bucket for Logs:**
```bash
aws s3 ls s3://your-bucket/ssm-outputs/ --recursive
aws s3 cp s3://your-bucket/ssm-outputs/deploy-nginx/stderr.txt ./
```

**Check CloudWatch Logs:**
```bash
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/docker-nginx"
aws logs get-log-events --log-group-name "/aws/ec2/docker-nginx" --log-stream-name <stream-name>
```

**Restart Application via SSM:**
```bash
aws ssm send-command \
  --document-name "DeployNginxContainer" \
  --targets "Key=InstanceIds,Values=<instance-id>" \
  --comment "Restarting failed nginx container"
```

### Real-World Monitoring Benefits

This monitoring setup provides:

1. **Proactive Alerts**: Know about problems before users complain
2. **Historical Data**: Understand usage patterns and plan capacity
3. **Troubleshooting Tools**: Logs and metrics help identify root causes
4. **Automated Recovery**: SSM documents can restart failed services
5. **Cost Optimization**: Identify over-provisioned resources

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Security Notes

- The default security group allows access from 0.0.0.0/0
- For production use, restrict `allowed_cidr_blocks` to your IP range
- Consider using AWS Session Manager for secure shell access instead of SSH

## Advanced Troubleshooting Guide

### Common Issues and Solutions

#### 1. Instance not appearing in SSM
**Symptoms**: EC2 instance doesn't show up in SSM console
**Causes**: 
- IAM role missing SSM permissions
- SSM agent not running
- Instance in private subnet without NAT gateway

**Solutions**:
```bash
# Check IAM role attachment
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Verify SSM agent status (via Session Manager or SSH)
sudo systemctl status amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Check SSM registration
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=<instance-id>"
```

#### 2. Docker installation failed
**Symptoms**: SSM command shows failure status
**Troubleshooting Steps**:
```bash
# Check S3 bucket for error logs
aws s3 cp s3://your-bucket/ssm-outputs/install-docker/stderr.txt ./

# Common issues and fixes:
# - Network connectivity: Check internet gateway and routes
# - Package conflicts: Update system first
# - Permissions: Ensure SSM has sudo access
```

#### 3. Nginx container won't start
**Symptoms**: Container exits immediately or fails to start
**Debugging Process**:
```bash
# Check container logs
docker logs nginx-container

# Check if port 80 is already in use
sudo netstat -tlnp | grep :80

# Verify Docker daemon is running
sudo systemctl status docker

# Check available disk space
df -h
```

#### 4. CloudWatch agent not sending metrics
**Symptoms**: No metrics appearing in CloudWatch console
**Resolution Steps**:
```bash
# Check agent status
sudo systemctl status amazon-cloudwatch-agent

# Review agent configuration
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent

# Check agent logs
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

#### 5. Email notifications not received
**Symptoms**: Alarms trigger but no emails arrive
**Verification Steps**:
```bash
# Check SNS topic subscription
aws sns list-subscriptions-by-topic --topic-arn <your-topic-arn>

# Verify email subscription is confirmed
# Check spam folder for confirmation email
# Manually confirm subscription if needed

# Test SNS topic
aws sns publish --topic-arn <your-topic-arn> --message "Test notification"
```

### Performance Optimization Tips

1. **Right-sizing**: Monitor CPU and memory usage to choose appropriate instance types
2. **Auto Scaling**: Consider implementing Auto Scaling Groups for production
3. **Load Balancing**: Use Application Load Balancer for high availability
4. **Caching**: Implement CloudFront for static content delivery
5. **Database**: Consider RDS for persistent data storage

### Production Readiness Checklist

- [ ] Restrict security group to specific IP ranges
- [ ] Enable detailed monitoring
- [ ] Set up log retention policies
- [ ] Implement backup strategies
- [ ] Configure SSL/TLS certificates
- [ ] Set up multiple availability zones
- [ ] Implement infrastructure as code best practices
- [ ] Set up CI/CD pipelines
- [ ] Configure monitoring dashboards
- [ ] Document runbooks for common issues

This infrastructure provides a solid foundation for learning cloud concepts and can be extended for production use with additional security and reliability features.
