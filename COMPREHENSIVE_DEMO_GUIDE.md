# Complete Docker Nginx EC2 Monitoring Demo - Comprehensive Guide for Beginners

## Table of Contents
1. [Overview - What Are We Building?](#overview)
2. [What is Terraform and How We're Using It](#terraform)
3. [Architecture Deep Dive - Every Component Explained](#architecture)
4. [Infrastructure Components - Building Blocks](#infrastructure)
5. [Monitoring Stack - The Observability Layer](#monitoring)
6. [Data Flow - How Information Moves](#data-flow)
7. [Step-by-Step Deployment Process](#deployment)
8. [Monitoring Capabilities - What We Can See](#monitoring-capabilities)
9. [Live Demo - Stress Testing and Alerting](#live-demo)

## Overview - What Are We Building? {#overview}

### The Big Picture
Imagine you're running a website (like Amazon, Netflix, or any web application). Users from around the world visit your site, and you need to know:
- Is my website working properly?
- How fast is it loading for users?
- Are there any errors happening?
- Is my server running out of memory or CPU?
- Which pages are most popular?
- If something breaks, how quickly can I know and fix it?

This demo creates a **complete monitoring solution** that answers all these questions automatically. We're building a simple website (using Nginx web server) that runs inside a Docker container on an Amazon EC2 server, but with **enterprise-grade monitoring** that tells us everything happening in real-time.

### What Makes This Special?
Instead of manually checking if our website is working, we're building an **intelligent system** that:
1. **Watches everything automatically** - CPU, memory, disk space, network traffic
2. **Tracks user behavior** - How long pages take to load, what users click on
3. **Sends alerts immediately** - If something goes wrong, we get an email instantly
4. **Stores historical data** - We can see trends and patterns over time
5. **Provides beautiful dashboards** - Visual charts and graphs showing system health

### Real-World Analogy
Think of this like a **smart home security system**:
- **Sensors everywhere** (monitoring agents) watch different parts of your house (server)
- **Central control panel** (CloudWatch dashboard) shows status of everything
- **Smart alerts** (CloudWatch alarms) notify you immediately if a door opens (CPU gets high) or motion is detected (errors occur)
- **Security cameras** (logs) record everything that happens
- **Mobile app** (RUM) shows you what's happening even when you're away

### Why Each Component Matters

**🏠 The House (EC2 Instance)**
- This is our server - a virtual computer in Amazon's data center
- Just like your home needs electricity and internet, our server needs CPU, memory, and network
- **Why important**: Without a reliable server, our website can't run

**🔧 The Foundation (VPC, Subnets, Security Groups)**
- Like the foundation, plumbing, and security system of a house
- VPC = your private neighborhood in AWS
- Subnet = your specific street address
- Security Group = your security system that controls who can enter
- **Why important**: Provides secure, isolated environment for our application

**📦 The Application (Docker + Nginx)**
- Docker = like a shipping container that packages our application
- Nginx = the web server that serves our website to users
- **Why important**: This is what users actually interact with

**👀 The Monitoring System (CloudWatch, RUM, X-Ray)**
- CloudWatch = like a security company monitoring your house 24/7
- RUM = like having cameras that show how visitors use your house
- X-Ray = like having a detailed map showing exactly where visitors go
- **Why important**: Without monitoring, we're blind to problems

**📧 The Alert System (SNS, Email)**
- Like having the security company call you immediately if there's a problem
- **Why important**: Fast notification means fast problem resolution

### What Happens When We're Done?
After running this demo, you'll have:
1. A working website at `http://3.92.55.245`
2. Real-time dashboards showing system health
3. Automatic alerts if anything goes wrong
4. Detailed logs of everything happening
5. User behavior tracking
6. Performance monitoring
7. A complete understanding of how enterprise monitoring works

This isn't just a simple website - it's a **production-ready, enterprise-grade system** with monitoring capabilities used by companies like Netflix, Airbnb, and Spotify.

## What is Terraform and How We're Using It {#terraform}

### What is Terraform? (Beginner Explanation)
Imagine you want to build a house. Traditionally, you would:
1. Call different contractors (electrician, plumber, carpenter)
2. Coordinate their work manually
3. Hope they all show up and do things correctly
4. If you want to build the same house again, repeat all steps manually

**Terraform is like having a master blueprint** that:
- Describes exactly what your "house" (infrastructure) should look like
- Automatically calls all the right "contractors" (AWS services)
- Ensures everything is built in the correct order
- Can rebuild the exact same "house" anywhere, anytime
- Keeps track of what's been built so you can modify or destroy it later

### Why Use Infrastructure as Code (IaC)?
**Traditional Way (Manual)**:
```
1. Login to AWS Console
2. Click "Create EC2 Instance"
3. Choose settings manually
4. Click "Create VPC"
5. Configure networking manually
6. Set up monitoring manually
7. Hope you remember all steps for next time
```

**Terraform Way (Automated)**:
```
1. Write code describing what you want
2. Run `terraform apply`
3. Everything gets created automatically
4. Want to create it again? Run the same command
5. Want to modify it? Change the code and run again
```

### Key Terraform Concepts in Our Demo

#### 1. **Providers - The "Contractors"**
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```
**What it does**: Tells Terraform "I want to use AWS services"
**Real-world analogy**: Like telling your general contractor "I want to build in California, so use California-licensed electricians and plumbers"
**Why we need it**: Terraform needs to know which cloud provider (AWS, Google Cloud, Azure) to use
**In our demo**: We use AWS provider version 5.x to create AWS resources

#### 2. **Resources - The "Building Materials"**
```hcl
resource "aws_instance" "docker_nginx" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  # ... other configuration
}
```
**What it does**: Creates actual AWS services (like EC2 instances, databases, networks)
**Real-world analogy**: Like saying "I want a 3-bedroom house with a 2-car garage"
**Why we need it**: Each resource represents a real AWS service we want to create
**In our demo**: We create 25+ resources including:
  - EC2 instance (our server)
  - VPC (our private network)
  - CloudWatch dashboards (our monitoring screens)
  - S3 buckets (our storage)
  - IAM roles (our security permissions)

#### 3. **Data Sources - The "Research"**
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  # ... filters
}
```
**What it does**: Looks up information about existing resources
**Real-world analogy**: Like researching "What's the latest model of Toyota Camry?" before buying
**Why we need it**: We need current information (like latest AMI ID) that changes over time
**In our demo**: We look up:
  - Latest Amazon Linux 2023 AMI (server image)
  - Available AWS regions
  - Our AWS account information

#### 4. **Variables - The "Customization Options"**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```
**What it does**: Makes our configuration flexible and reusable
**Real-world analogy**: Like having options for "paint color" and "flooring type" when building a house
**Why we need it**: Allows customization without changing the main code
**In our demo**: We use variables for:
  - AWS region (where to build)
  - Instance name (what to call our server)
  - Environment (Development, Production, etc.)

#### 5. **Outputs - The "Final Report"**
```hcl
output "nginx_url" {
  description = "URL to access the Nginx application"
  value       = "http://${aws_instance.docker_nginx.public_ip}"
}
```
**What it does**: Shows important information after everything is built
**Real-world analogy**: Like getting the final address and keys after your house is built
**Why we need it**: Provides access URLs, IDs, and other important values we need
**In our demo**: We output:
  - Website URL (where to access our application)
  - Dashboard URLs (where to see monitoring)
  - Instance IDs (for troubleshooting)

### How Terraform Works in Our Demo (Step by Step)

#### Phase 1: Planning (`terraform plan`)
**What happens**:
1. Terraform reads all `.tf` files in our directory
2. Connects to AWS to see what currently exists
3. Compares what we want vs. what exists
4. Creates a "construction plan" showing what will be built

**Real-world analogy**: Like an architect reviewing blueprints and saying "We need to build a foundation, then walls, then roof"

**What you see**:
```
Plan: 25 to add, 0 to change, 0 to destroy.
+ aws_vpc.main
+ aws_subnet.public
+ aws_instance.docker_nginx
...
```

#### Phase 2: Building (`terraform apply`)
**What happens**:
1. Terraform starts creating resources in the correct order
2. Waits for each resource to be ready before creating dependent resources
3. Handles any errors and retries if needed
4. Updates the state file to track what was created

**Real-world analogy**: Like construction crews showing up in the right order - foundation crew first, then framers, then electricians

**Dependency Example**:
```
VPC must be created first
↓
Subnet must be created after VPC
↓
Security Group must be created after VPC
↓
EC2 Instance must be created after Subnet and Security Group
```

#### Phase 3: State Management
**What happens**:
- Terraform creates a `terraform.tfstate` file
- This file tracks every resource that was created
- Includes resource IDs, properties, and relationships
- Used for future updates and deletions

**Real-world analogy**: Like keeping detailed records of every contractor, material, and permit used in building your house

**Why it's important**:
- Enables updates (changing instance size)
- Enables cleanup (destroying everything)
- Prevents conflicts (two people trying to manage same resources)

### Terraform Commands We Use

#### `terraform init`
**Purpose**: Downloads required providers and sets up working directory
**When to use**: First time in a new directory, or when providers change
**What it does**:
```bash
# Downloads AWS provider (~200MB)
# Creates .terraform/ directory
# Creates .terraform.lock.hcl file
```

#### `terraform plan`
**Purpose**: Shows what will be created/changed/destroyed
**When to use**: Before applying changes to see what will happen
**What it does**:
```bash
# Reads all .tf files
# Connects to AWS to check current state
# Shows a preview of changes
# No actual changes are made
```

#### `terraform apply`
**Purpose**: Actually creates/modifies/destroys resources
**When to use**: After reviewing the plan and confirming changes
**What it does**:
```bash
# Creates resources in dependency order
# Updates state file
# Shows progress and any errors
# Provides outputs when complete
```

#### `terraform destroy`
**Purpose**: Removes all resources created by Terraform
**When to use**: When you want to clean up and stop paying for resources
**What it does**:
```bash
# Destroys resources in reverse dependency order
# Updates state file
# Removes everything tracked by Terraform
```

### Why This Approach is Powerful

#### **Repeatability**
- Run the same code in different AWS accounts
- Create identical environments for development, testing, production
- New team member can recreate entire environment with one command

#### **Version Control**
- Store Terraform code in Git
- Track changes over time
- Collaborate with team members
- Roll back to previous versions if needed

#### **Documentation**
- The code itself documents your infrastructure
- No more "tribal knowledge" about how things were set up
- New team members can understand the setup by reading code

#### **Safety**
- Preview changes before applying them
- Terraform prevents you from accidentally breaking dependencies
- State file prevents conflicts between team members

This Infrastructure as Code approach is used by companies like Netflix, Airbnb, and Spotify to manage thousands of servers and services reliably.

## Architecture Deep Dive {#architecture}

### High-Level Architecture Flow:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │───▶│    Terraform     │───▶│   AWS Cloud     │
│   (You)         │    │   Configuration  │    │   Resources     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  Infrastructure  │
                       │   Deployment     │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Monitoring &   │
                       │   Observability  │
                       └──────────────────┘
```

### Detailed Component Architecture:

```
                    ┌─────────────────────────────────────────────────────────┐
                    │                    AWS CLOUD                           │
                    │                                                         │
    ┌───────────────┼─────────────────────────────────────────────────────────┼───────────────┐
    │               │                  VPC (10.0.0.0/16)                     │               │
    │               │                                                         │               │
    │   ┌───────────┼─────────────────────────────────────────────────────────┼───────────┐   │
    │   │           │            Public Subnet (10.0.1.0/24)                 │           │   │
    │   │           │                                                         │           │   │
    │   │   ┌───────┼─────────────────────────────────────────────────────────┼───────┐   │   │
    │   │   │       │                EC2 Instance                            │       │   │   │
    │   │   │       │              (t2.micro)                                │       │   │   │
    │   │   │       │                                                         │       │   │   │
    │   │   │   ┌───┼─────────────────────────────────────────────────────────┼───┐   │   │   │
    │   │   │   │   │                                                         │   │   │   │   │
    │   │   │   │   │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │   │   │   │   │
    │   │   │   │   │  │ CloudWatch  │  │   X-Ray     │  │   Docker    │    │   │   │   │   │
    │   │   │   │   │  │   Agent     │  │   Daemon    │  │   Engine    │    │   │   │   │   │
    │   │   │   │   │  └─────────────┘  └─────────────┘  └─────────────┘    │   │   │   │   │
    │   │   │   │   │                          │                             │   │   │   │   │
    │   │   │   │   │                          ▼                             │   │   │   │   │
    │   │   │   │   │                 ┌─────────────┐                        │   │   │   │   │
    │   │   │   │   │                 │   Nginx     │                        │   │   │   │   │
    │   │   │   │   │                 │ Container   │                        │   │   │   │   │
    │   │   │   │   │                 │  (Port 80)  │                        │   │   │   │   │
    │   │   │   │   │                 └─────────────┘                        │   │   │   │   │
    │   │   │   │   └─────────────────────────────────────────────────────────┘   │   │   │   │
    │   │   │   └─────────────────────────────────────────────────────────────────┘   │   │   │
    │   │   └─────────────────────────────────────────────────────────────────────────┘   │   │
    │   └─────────────────────────────────────────────────────────────────────────────────┘   │
    └─────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
    ┌─────────────────────────────────────────────────────────────────────────────────────────┐
    │                           MONITORING & OBSERVABILITY                                   │
    │                                                                                         │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
    │  │ CloudWatch  │  │ CloudWatch  │  │    X-Ray    │  │    RUM      │  │     SNS     │  │
    │  │ Dashboard   │  │   Alarms    │  │   Tracing   │  │ Monitoring  │  │   Alerts    │  │
    │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │
    │                                                                                         │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
    │  │ CloudWatch  │  │     S3      │  │   Cognito   │  │    IAM      │  │    SSM      │  │
    │  │    Logs     │  │   Buckets   │  │ Identity    │  │   Roles     │  │ Documents   │  │
    │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │
    └─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Infrastructure Components {#infrastructure}

### 1. **Networking Layer**

#### VPC (Virtual Private Cloud)
```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```
- **Purpose**: Creates isolated network environment
- **CIDR Block**: 10.0.0.0/16 (65,536 IP addresses)
- **DNS**: Enabled for hostname resolution
- **Why needed**: Provides network isolation and security

#### Public Subnet
```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}
```
- **Purpose**: Hosts EC2 instance with internet access
- **CIDR Block**: 10.0.1.0/24 (256 IP addresses)
- **Public IPs**: Automatically assigned
- **Why needed**: Allows internet access for web application

#### Internet Gateway
```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```
- **Purpose**: Provides internet connectivity
- **Function**: Routes traffic between VPC and internet
- **Why needed**: Enables inbound/outbound internet access

#### Route Table & Association
```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
```
- **Purpose**: Defines routing rules
- **Default Route**: 0.0.0.0/0 → Internet Gateway
- **Why needed**: Directs traffic to internet gateway

### 2. **Security Layer**

#### Security Group
```hcl
resource "aws_security_group" "docker_nginx_sg" {
  name_prefix = "docker-nginx-sg"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
- **Purpose**: Acts as virtual firewall
- **Inbound Rules**: 
  - Port 80 (HTTP) from anywhere
  - Port 443 (HTTPS) from anywhere
- **Outbound Rules**: All traffic allowed
- **Why needed**: Controls network access to EC2 instance

### 3. **Compute Layer**

#### EC2 Instance
```hcl
resource "aws_instance" "docker_nginx" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.docker_nginx_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name
  user_data              = base64encode(templatefile("${path.module}/user_data_enhanced.sh", {
    s3_bucket = aws_s3_bucket.ssm_output_bucket.bucket
  }))
}
```
- **AMI**: Amazon Linux 2023 (latest)
- **Instance Type**: t2.micro (1 vCPU, 1GB RAM)
- **IAM Profile**: Attached for AWS service access
- **User Data**: Bootstrap script for initial setup
- **Why needed**: Hosts our containerized application

#### User Data Script Deep Dive
The user data script (`user_data_enhanced.sh`) runs when the instance first boots:

1. **System Updates**:
   ```bash
   yum update -y
   ```
   - Updates all system packages
   - Ensures security patches are applied

2. **CloudWatch Agent Installation**:
   ```bash
   wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
   rpm -U ./amazon-cloudwatch-agent.rpm
   ```
   - Downloads and installs CloudWatch agent
   - Enables detailed system metrics collection

3. **X-Ray Daemon Installation**:
   ```bash
   curl https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o xray.rpm
   yum install -y xray.rpm
   ```
   - Installs X-Ray daemon for distributed tracing
   - Configures trace collection and forwarding

4. **Service Configuration**:
   - Starts and enables CloudWatch agent
   - Starts and enables X-Ray daemon
   - Ensures SSM agent is running

### 4. **Identity and Access Management (IAM)**

#### IAM Role for EC2
```hcl
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
```
- **Purpose**: Defines what AWS services EC2 can access
- **Trust Policy**: Allows EC2 service to assume this role
- **Why needed**: Enables EC2 to interact with AWS services securely

#### Attached Policies
1. **AmazonSSMManagedInstanceCore**: SSM management capabilities
2. **CloudWatchAgentServerPolicy**: CloudWatch metrics and logs
3. **Custom X-Ray Policy**: X-Ray trace submission
4. **Custom S3 Policy**: S3 bucket access for SSM outputs

### 5. **Systems Manager (SSM) Automation**

#### SSM Documents
SSM Documents define automation scripts that run on EC2 instances:

##### Docker Installation Document
```yaml
schemaVersion: '2.2'
description: Install Docker with enhanced monitoring and logging
parameters:
  logLevel:
    type: String
    description: Log level for Docker daemon
    default: info
mainSteps:
  - action: aws:runShellScript
    name: installDocker
    inputs:
      timeoutSeconds: '600'
      runCommand:
        - |
          #!/bin/bash
          # Install Docker
          yum update -y
          yum install -y docker
          # Configure Docker daemon
          # Start and enable Docker
          # Install Docker Compose
```

**What happens**:
1. Updates system packages
2. Installs Docker engine
3. Configures Docker daemon with logging
4. Starts Docker service
5. Installs Docker Compose
6. Creates log files

##### Nginx Deployment Document
```yaml
schemaVersion: '2.2'
description: Deploy Nginx container with enhanced monitoring
parameters:
  nginxImage:
    type: String
    default: nginx:latest
  containerName:
    type: String
    default: nginx-app
mainSteps:
  - action: aws:runShellScript
    name: deployNginx
    inputs:
      runCommand:
        - |
          # Stop existing container
          # Create custom nginx configuration
          # Deploy new container with monitoring
          # Test deployment
```

**What happens**:
1. Stops any existing Nginx container
2. Creates custom Nginx configuration with:
   - Enhanced logging format
   - Health check endpoint (/health)
   - Status endpoint (/nginx_status)
   - Response time headers
3. Creates custom HTML page with monitoring info
4. Deploys Nginx container with volume mounts
5. Tests deployment with health check

#### SSM Associations
```hcl
resource "aws_ssm_association" "install_docker_enhanced" {
  name = aws_ssm_document.install_docker_enhanced.name
  targets {
    key    = "tag:SSMManaged"
    values = ["true"]
  }
}
```
- **Purpose**: Automatically runs SSM documents on tagged instances
- **Targeting**: Uses EC2 tags to identify target instances
- **Scheduling**: Can run once or on schedule
- **Why needed**: Automates software installation and configuration

## Monitoring Stack {#monitoring}

### 1. **CloudWatch Metrics and Dashboard**

#### CloudWatch Agent Configuration
```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/docker-nginx",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/docker-nginx",
            "log_stream_name": "{instance_id}/nginx-access"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
```

**What it collects**:
- **System Metrics**: CPU, memory, disk usage
- **Network Metrics**: Network I/O statistics
- **Process Metrics**: Running processes count
- **Log Files**: System logs, Docker logs, Nginx logs

#### CloudWatch Dashboard
The dashboard provides visual representation of:
- **CPU Metrics Widget**: Shows CPU utilization breakdown
- **Memory & Status Widget**: Memory usage and EC2 status checks
- **Disk Usage Widget**: Disk utilization and I/O metrics
- **Network Widget**: Network throughput metrics
- **Logs Widget**: Recent log entries with CloudWatch Insights query

### 2. **CloudWatch Alarms**

#### High CPU Alarm
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "docker-nginx-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```
- **Threshold**: 80% CPU utilization
- **Evaluation**: 2 consecutive periods (10 minutes)
- **Action**: Sends SNS notification
- **Purpose**: Alerts when CPU usage is high

#### Memory and Disk Alarms
Similar configuration for:
- **Memory**: Triggers at 85% usage
- **Disk**: Triggers at 90% usage

### 3. **Real User Monitoring (RUM)**

#### RUM App Monitor
```hcl
resource "aws_rum_app_monitor" "nginx_rum" {
  name   = "nginx-app-monitor"
  domain = "3.92.55.245"
  
  app_monitor_configuration {
    allow_cookies       = true
    enable_xray         = true
    session_sample_rate = 0.1
    telemetries         = ["errors", "performance", "http"]
    favorite_pages      = ["/", "/health"]
  }
}
```

**What it monitors**:
- **Page Load Performance**: Load times, render times
- **User Interactions**: Clicks, navigation patterns
- **JavaScript Errors**: Client-side error tracking
- **HTTP Requests**: API call performance
- **Custom Events**: Application-specific metrics

#### RUM Integration
The web application includes RUM JavaScript SDK:
```javascript
(function(n,i,v,r,s,c,x,z){
  // RUM SDK initialization
  x=window.AwsRumClient={q:[],n:n,i:i,v:v,r:r,c:c};
  // Custom event tracking
  cwr('recordEvent', {
    name: 'page_performance',
    details: {
      loadTime: loadTime,
      domReady: domReady
    }
  });
})();
```

### 4. **X-Ray Distributed Tracing**

#### X-Ray Daemon Configuration
```yaml
TotalBufferSizeInMB: 0
Concurrency: 8
Region: us-east-1
Socket:
  UDPAddress: "0.0.0.0:2000"
  TCPAddress: "0.0.0.0:2000"
LocalMode: false
LogLevel: prod
LogPath: "/var/log/xray/xray.log"
```

#### X-Ray Sampling Rule
```hcl
resource "aws_xray_sampling_rule" "nginx_sampling" {
  rule_name      = "nginx-sampling-rule"
  priority       = 9000
  fixed_rate     = 0.1
  reservoir_size = 1
  service_name   = "nginx-app"
}
```
- **Sampling Rate**: 10% of requests
- **Service**: nginx-app
- **Purpose**: Controls trace collection volume

### 5. **Log Management**

#### CloudWatch Log Groups
- **Main Log Group**: `/aws/ec2/docker-nginx`
- **Log Streams**:
  - `{instance_id}/messages`: System messages
  - `{instance_id}/docker`: Docker daemon logs
  - `{instance_id}/nginx-access`: Nginx access logs
  - `{instance_id}/nginx-error`: Nginx error logs
  - `{instance_id}/xray`: X-Ray daemon logs

#### Enhanced Nginx Logging
```nginx
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
               '$status $body_bytes_sent "$http_referer" '
               '"$http_user_agent" "$http_x_forwarded_for" '
               'rt=$request_time uct="$upstream_connect_time" '
               'uht="$upstream_header_time" urt="$upstream_response_time"';
```
- **Captures**: IP, timestamp, request, response time
- **Response Time**: Included for performance analysis
- **Upstream Timing**: For backend performance tracking

#### CloudWatch Insights Queries
Pre-built queries for log analysis:

1. **Error Analysis**:
   ```sql
   fields @timestamp, @message
   | filter @message like /ERROR/
   | stats count() by bin(5m)
   | sort @timestamp desc
   ```

2. **Performance Analysis**:
   ```sql
   fields @timestamp, @message
   | filter @message like /response_time/
   | parse @message /response_time: (?<response_time>\d+)/
   | stats avg(response_time), max(response_time), min(response_time) by bin(5m)
   ```

This completes Part 1 of the comprehensive guide. Would you like me to continue with the remaining sections covering Data Flow, Deployment Process, and Monitoring Capabilities?
