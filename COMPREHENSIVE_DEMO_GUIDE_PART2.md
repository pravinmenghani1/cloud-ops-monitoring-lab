# Complete Docker Nginx EC2 Monitoring Demo - Part 2

## Data Flow Analysis {#data-flow}

### 1. **User Request Flow**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Browser   │───▶│   Internet  │───▶│     ALB     │───▶│    EC2      │
│   (User)    │    │   Gateway   │    │  (Optional) │    │  Instance   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
                                                                ▼
                                                       ┌─────────────┐
                                                       │   Docker    │
                                                       │   Engine    │
                                                       └─────────────┘
                                                                │
                                                                ▼
                                                       ┌─────────────┐
                                                       │    Nginx    │
                                                       │  Container  │
                                                       └─────────────┘
```

**Step-by-step breakdown**:

1. **User Request Initiation**:
   - User opens browser and navigates to `http://3.92.55.245`
   - Browser initiates HTTP GET request

2. **Network Routing**:
   - Request travels through internet to AWS
   - Hits Internet Gateway attached to our VPC
   - Routes through VPC routing table to public subnet

3. **Security Group Filtering**:
   - Security group evaluates inbound rules
   - Port 80 (HTTP) traffic is allowed from 0.0.0.0/0
   - Request passes through to EC2 instance

4. **EC2 Instance Processing**:
   - Request hits EC2 instance on port 80
   - Docker engine receives the request
   - Forwards to Nginx container running on port 80

5. **Nginx Processing**:
   - Nginx processes the HTTP request
   - Serves static content from `/usr/share/nginx/html`
   - Logs request details with response time
   - Returns HTTP response

### 2. **Monitoring Data Flow**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EC2 INSTANCE                                  │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ CloudWatch  │  │   X-Ray     │  │   Nginx     │  │   System    │       │
│  │   Agent     │  │   Daemon    │  │  Container  │  │   Logs      │       │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
│         │                 │                 │                 │           │
│         ▼                 ▼                 ▼                 ▼           │
└─────────┼─────────────────┼─────────────────┼─────────────────┼───────────┘
          │                 │                 │                 │
          ▼                 ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS MONITORING SERVICES                          │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ CloudWatch  │  │    X-Ray    │  │ CloudWatch  │  │     RUM     │       │
│  │   Metrics   │  │   Traces    │  │    Logs     │  │   Events    │       │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
│         │                 │                 │                 │           │
│         ▼                 ▼                 ▼                 ▼           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │ CloudWatch  │  │   Service   │  │   Insights  │  │   User      │       │
│  │ Dashboard   │  │     Map     │  │   Queries   │  │ Experience  │       │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### Detailed Data Collection Process:

**A. CloudWatch Agent Data Collection**:
```bash
# Agent collects every 60 seconds:
- CPU metrics (idle, user, system, iowait)
- Memory metrics (used percentage, available)
- Disk metrics (used percentage, I/O operations)
- Network metrics (bytes in/out, packets)
- Process metrics (running, sleeping, dead)
```

**B. Log Collection Process**:
```bash
# CloudWatch Agent monitors these files:
/var/log/messages          → System messages
/var/log/docker.log        → Docker daemon logs
/var/log/nginx/access.log  → HTTP access logs with response times
/var/log/nginx/error.log   → Nginx error logs
/var/log/xray/xray.log     → X-Ray daemon logs
```

**C. X-Ray Trace Collection**:
```bash
# X-Ray Daemon process:
1. Listens on UDP port 2000
2. Receives trace segments from applications
3. Buffers traces locally
4. Sends batched traces to X-Ray service
5. Applies sampling rules (10% in our case)
```

**D. RUM Data Collection**:
```javascript
// Browser-side data collection:
- Page load performance metrics
- User interaction events (clicks, navigation)
- JavaScript errors and exceptions
- Custom application events
- Network request performance
```

### 3. **Alert Flow**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ CloudWatch  │───▶│ CloudWatch  │───▶│     SNS     │───▶│    Email    │
│   Metrics   │    │   Alarms    │    │    Topic    │    │   Notify    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Alert Trigger Process**:
1. **Metric Evaluation**: CloudWatch evaluates metrics every 5 minutes
2. **Threshold Comparison**: Compares against defined thresholds
3. **Alarm State Change**: Changes from OK to ALARM state
4. **SNS Notification**: Publishes message to SNS topic
5. **Subscriber Notification**: Sends email/SMS to subscribers

## Step-by-Step Deployment Process {#deployment}

### Phase 1: Infrastructure Initialization

#### Step 1: Terraform Initialization
```bash
terraform init
```

**What happens internally**:
1. **Provider Download**: Downloads AWS provider plugin (~200MB)
2. **Backend Initialization**: Sets up local state backend
3. **Module Resolution**: Resolves any module dependencies
4. **Lock File Creation**: Creates `.terraform.lock.hcl` with provider versions

**Files created**:
- `.terraform/` directory with provider binaries
- `.terraform.lock.hcl` with version constraints

#### Step 2: Terraform Planning
```bash
terraform plan
```

**What happens internally**:
1. **Configuration Parsing**: Reads all `.tf` files
2. **State Comparison**: Compares desired vs current state
3. **Dependency Graph**: Builds resource dependency graph
4. **API Calls**: Makes AWS API calls to check current resources
5. **Plan Generation**: Creates execution plan

**Output analysis**:
- `+` indicates resources to be created
- `~` indicates resources to be modified
- `-` indicates resources to be destroyed
- Shows 25+ resources to be created

#### Step 3: Terraform Apply
```bash
terraform apply -auto-approve
```

**Execution order** (based on dependencies):
1. **Data Sources**: Fetch AMI, AZs, caller identity
2. **Random Resources**: Generate bucket suffix
3. **IAM Resources**: Roles, policies, instance profile
4. **VPC Resources**: VPC, subnet, IGW, route table
5. **Security Groups**: Network access rules
6. **S3 Resources**: Buckets for SSM outputs and RUM assets
7. **CloudWatch Resources**: Log groups, dashboard, alarms
8. **SSM Resources**: Documents and associations
9. **EC2 Instance**: Main compute resource
10. **Monitoring Resources**: RUM, X-Ray, Cognito

### Phase 2: Instance Bootstrap

#### Step 1: User Data Execution
When EC2 instance launches, user data script runs:

```bash
#!/bin/bash
# Script runs as root user
# Logs to /var/log/cloud-init-output.log

# 1. System Updates (2-3 minutes)
yum update -y

# 2. CloudWatch Agent Installation (1-2 minutes)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# 3. X-Ray Daemon Installation (1 minute)
curl https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o xray.rpm
yum install -y xray.rpm

# 4. Service Configuration (30 seconds)
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
systemctl start xray
systemctl enable xray
```

**Timeline**:
- **T+0**: Instance launches, user data starts
- **T+2min**: System updates complete
- **T+4min**: CloudWatch agent installed and configured
- **T+5min**: X-Ray daemon installed and running
- **T+6min**: Instance ready for SSM management

#### Step 2: SSM Agent Registration
```bash
# SSM agent (pre-installed on Amazon Linux 2023)
systemctl status amazon-ssm-agent
# Status: Active (running)
```

**Registration process**:
1. **IAM Role Verification**: Checks attached IAM role
2. **Service Registration**: Registers with SSM service
3. **Heartbeat Establishment**: Starts sending heartbeats
4. **Command Readiness**: Ready to receive SSM commands

### Phase 3: Application Deployment

#### Step 1: Docker Installation via SSM
SSM Association triggers Docker installation:

```yaml
# SSM Document: InstallDockerEnhanced
schemaVersion: '2.2'
description: Install Docker with enhanced monitoring and logging
mainSteps:
  - action: aws:runShellScript
    name: installDocker
    inputs:
      timeoutSeconds: '600'
      runCommand:
        - |
          # Install Docker
          yum update -y
          yum install -y docker
          
          # Configure Docker daemon
          mkdir -p /etc/docker
          cat > /etc/docker/daemon.json << 'EOF'
          {
            "log-driver": "json-file",
            "log-opts": {
              "max-size": "10m",
              "max-file": "3"
            },
            "metrics-addr": "0.0.0.0:9323",
            "experimental": true
          }
          EOF
          
          # Start Docker
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
```

**Execution timeline**:
- **T+0**: SSM receives command
- **T+1min**: Docker packages downloaded and installed
- **T+2min**: Docker daemon configured with logging
- **T+3min**: Docker service started and enabled
- **T+4min**: Docker installation complete

#### Step 2: Nginx Container Deployment
Second SSM Association deploys Nginx:

```yaml
# SSM Document: DeployNginxContainerEnhanced
schemaVersion: '2.2'
description: Deploy Nginx container with enhanced monitoring
mainSteps:
  - action: aws:runShellScript
    name: deployNginx
    inputs:
      runCommand:
        - |
          # Create custom nginx configuration
          mkdir -p /opt/nginx/conf
          cat > /opt/nginx/conf/nginx.conf << 'EOF'
          events {
              worker_connections 1024;
          }
          
          http {
              # Enhanced logging format with response times
              log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                             '$status $body_bytes_sent "$http_referer" '
                             '"$http_user_agent" "$http_x_forwarded_for" '
                             'rt=$request_time';
              
              access_log /var/log/nginx/access.log main;
              error_log /var/log/nginx/error.log warn;
              
              server {
                  listen 80;
                  
                  # Health check endpoint
                  location /health {
                      return 200 "healthy\n";
                      add_header Content-Type text/plain;
                  }
                  
                  # Nginx status endpoint
                  location /nginx_status {
                      stub_status on;
                      allow 127.0.0.1;
                      allow 10.0.0.0/8;
                      deny all;
                  }
                  
                  location / {
                      root /usr/share/nginx/html;
                      index index.html;
                      add_header X-Response-Time $request_time;
                  }
              }
          }
          EOF
          
          # Deploy container
          docker run -d \
            --name nginx-app \
            --restart unless-stopped \
            -p 80:80 \
            -v /opt/nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro \
            -v /opt/nginx/html:/usr/share/nginx/html:ro \
            -v /var/log/nginx:/var/log/nginx \
            nginx:latest
```

**Container deployment process**:
1. **Configuration Creation**: Custom nginx.conf with monitoring
2. **HTML Content**: Custom index page with monitoring info
3. **Container Launch**: Docker run with volume mounts
4. **Health Check**: Verify container is responding
5. **Log Integration**: Nginx logs flow to CloudWatch

### Phase 4: Monitoring Activation

#### Step 1: CloudWatch Metrics Collection
```bash
# CloudWatch agent starts collecting:
- CPU metrics every 60 seconds
- Memory metrics every 60 seconds  
- Disk metrics every 60 seconds
- Network metrics every 60 seconds
- Log files continuously
```

#### Step 2: X-Ray Trace Collection
```bash
# X-Ray daemon configuration:
- Listens on UDP port 2000
- Buffers traces locally
- Sends to X-Ray service every 1 second
- Applies 10% sampling rate
```

#### Step 3: RUM Integration
```javascript
// Browser-side RUM initialization
(function(n,i,v,r,s,c,x,z){
  // RUM client setup with:
  // - App Monitor ID: 0037c2b5-b82e-4ab5-8ea5-1d0df79328df
  // - Identity Pool: us-east-1:0f32b4c4-b236-4434-9f8b-a8efbae0daf6
  // - Session sampling: 10%
  // - Telemetries: errors, performance, http
})();
```

## Monitoring Capabilities Deep Dive {#monitoring-capabilities}

### 1. **Infrastructure Monitoring**

#### CPU Monitoring
**Metrics collected**:
- `CPUUtilization` (AWS/EC2 namespace)
- `cpu_usage_idle` (CWAgent namespace)
- `cpu_usage_user` (CWAgent namespace)
- `cpu_usage_system` (CWAgent namespace)
- `cpu_usage_iowait` (CWAgent namespace)

**Visualization**:
```json
{
  "metrics": [
    ["AWS/EC2", "CPUUtilization", "InstanceId", "i-0c044afadee5a0596"],
    ["CWAgent", "cpu_usage_idle", "InstanceId", "i-0c044afadee5a0596"],
    [".", "cpu_usage_user", ".", "."],
    [".", "cpu_usage_system", ".", "."]
  ],
  "period": 300,
  "stat": "Average",
  "region": "us-east-1",
  "title": "EC2 CPU Metrics"
}
```

**Alerting**:
- **Threshold**: 80% average over 10 minutes
- **Action**: SNS notification
- **Use case**: Detect high CPU usage indicating performance issues

#### Memory Monitoring
**Metrics collected**:
- `mem_used_percent` (CWAgent namespace)
- `mem_available_percent` (CWAgent namespace)

**Analysis capabilities**:
- Memory usage trends over time
- Memory leak detection
- Capacity planning insights

#### Disk Monitoring
**Metrics collected**:
- `disk_used_percent` (CWAgent namespace)
- `diskio_io_time` (CWAgent namespace)
- `diskio_read_bytes` (CWAgent namespace)
- `diskio_write_bytes` (CWAgent namespace)

**Use cases**:
- Disk space monitoring
- I/O performance analysis
- Storage capacity planning

#### Network Monitoring
**Metrics collected**:
- `NetworkIn` (AWS/EC2 namespace)
- `NetworkOut` (AWS/EC2 namespace)
- `NetworkPacketsIn` (AWS/EC2 namespace)
- `NetworkPacketsOut` (AWS/EC2 namespace)

### 2. **Application Performance Monitoring**

#### Nginx Access Log Analysis
**Log format**:
```
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for" rt=$request_time
```

**Sample log entry**:
```
203.0.113.12 - - [03/Aug/2025:10:30:45 +0000] "GET / HTTP/1.1" 200 1234 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "-" rt=0.003
```

**CloudWatch Insights queries**:

1. **Response Time Analysis**:
```sql
fields @timestamp, @message
| filter @message like /rt=/
| parse @message /rt=(?<response_time>\d+\.\d+)/
| stats avg(response_time), max(response_time), min(response_time), count() by bin(5m)
| sort @timestamp desc
```

2. **Status Code Analysis**:
```sql
fields @timestamp, @message
| parse @message /"(?<method>\w+) (?<url>\S+) HTTP\/[\d\.]+" (?<status>\d+)/
| stats count() by status
| sort count desc
```

3. **Top URLs**:
```sql
fields @timestamp, @message
| parse @message /"(?<method>\w+) (?<url>\S+) HTTP\/[\d\.]+" (?<status>\d+)/
| stats count() by url
| sort count desc
| limit 10
```

#### Health Check Monitoring
**Endpoint**: `http://3.92.55.245/health`
**Response**: `healthy`
**Monitoring**:
- Automated health checks via CloudWatch Synthetics (can be added)
- Response time tracking
- Availability monitoring

#### Nginx Status Monitoring
**Endpoint**: `http://3.92.55.245/nginx_status` (internal only)
**Metrics provided**:
```
Active connections: 1
server accepts handled requests
 123 123 456
Reading: 0 Writing: 1 Waiting: 0
```

### 3. **User Experience Monitoring (RUM)**

#### Page Performance Metrics
**Collected automatically**:
- **Page Load Time**: Total time to load page
- **DOM Ready Time**: Time until DOM is ready
- **First Paint**: Time to first visual element
- **Largest Contentful Paint**: Time to largest element
- **Cumulative Layout Shift**: Visual stability metric

#### Custom Event Tracking
**JavaScript implementation**:
```javascript
// Custom performance tracking
window.addEventListener('load', function() {
    const perfData = performance.getEntriesByType('navigation')[0];
    const loadTime = Math.round(perfData.loadEventEnd - perfData.fetchStart);
    
    // Send to RUM
    cwr('recordEvent', {
        name: 'page_performance',
        details: {
            loadTime: loadTime,
            domReady: Math.round(perfData.domContentLoadedEventEnd - perfData.fetchStart)
        }
    });
});

// Button click tracking
document.addEventListener('click', function(e) {
    if (e.target.tagName === 'BUTTON') {
        cwr('recordEvent', {
            name: 'button_click',
            details: { buttonText: e.target.textContent }
        });
    }
});
```

#### Error Tracking
**Automatic error capture**:
- JavaScript runtime errors
- Network request failures
- Resource loading failures
- Custom error events

### 4. **Distributed Tracing (X-Ray)**

#### Trace Collection
**X-Ray daemon configuration**:
```yaml
TotalBufferSizeInMB: 0
Concurrency: 8
Region: us-east-1
Socket:
  UDPAddress: "0.0.0.0:2000"
  TCPAddress: "0.0.0.0:2000"
LocalMode: false
LogLevel: prod
```

#### Sampling Strategy
**Sampling rule**:
- **Service**: nginx-app
- **Fixed Rate**: 10% of requests
- **Reservoir**: 1 request per second minimum
- **Priority**: 9000 (lower priority)

#### Service Map
**Components traced**:
- HTTP requests to Nginx
- Downstream service calls (if any)
- Database queries (if configured)
- External API calls (if configured)

### 5. **Log Analysis and Insights**

#### Log Aggregation
**Log sources**:
- **System Logs**: `/var/log/messages`
- **Docker Logs**: `/var/log/docker.log`
- **Nginx Access**: `/var/log/nginx/access.log`
- **Nginx Errors**: `/var/log/nginx/error.log`
- **X-Ray Logs**: `/var/log/xray/xray.log`

#### Pre-built Queries

1. **Error Rate Analysis**:
```sql
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /error/ or @message like /Error/
| stats count() as error_count by bin(5m)
| sort @timestamp desc
```

2. **Request Volume Analysis**:
```sql
fields @timestamp, @message
| filter @message like /GET/ or @message like /POST/
| stats count() as request_count by bin(1m)
| sort @timestamp desc
```

3. **Performance Degradation Detection**:
```sql
fields @timestamp, @message
| filter @message like /rt=/
| parse @message /rt=(?<response_time>\d+\.\d+)/
| stats avg(response_time) as avg_response_time by bin(5m)
| sort @timestamp desc
```

### 6. **Alerting and Notifications**

#### Alert Configuration
**SNS Topic**: `arn:aws:sns:us-east-1:237083716140:docker-nginx-alerts`

**Alarm Types**:
1. **Infrastructure Alarms**:
   - High CPU (>80%)
   - High Memory (>85%)
   - Low Disk Space (>90%)

2. **Application Alarms** (can be added):
   - High Error Rate
   - Slow Response Time
   - Low Availability

#### Notification Channels
**Current**: SNS topic (email/SMS can be subscribed)
**Possible additions**:
- Slack integration
- PagerDuty integration
- AWS Chatbot for Teams/Slack

This completes the comprehensive technical deep-dive of our monitoring demo. The next step would be to add the missing monitoring components you mentioned and create visual architecture diagrams.
