#!/bin/bash
yum update -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Install X-Ray daemon
curl https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o xray.rpm
yum install -y xray.rpm

# Create enhanced CloudWatch agent configuration with more detailed metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 30,
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
                        "file_path": "/var/log/docker.log",
                        "log_group_name": "/aws/ec2/docker-nginx",
                        "log_stream_name": "{instance_id}/docker"
                    },
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/docker-nginx",
                        "log_stream_name": "{instance_id}/nginx-access"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/docker-nginx",
                        "log_stream_name": "{instance_id}/nginx-error"
                    },
                    {
                        "file_path": "/var/log/xray/xray.log",
                        "log_group_name": "/aws/ec2/docker-nginx",
                        "log_stream_name": "{instance_id}/xray"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 30,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent",
                    "inodes_free"
                ],
                "metrics_collection_interval": 30,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "read_bytes",
                    "write_bytes",
                    "reads",
                    "writes"
                ],
                "metrics_collection_interval": 30,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent",
                    "mem_available_percent"
                ],
                "metrics_collection_interval": 30
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 30
            },
            "processes": {
                "measurement": [
                    "running",
                    "sleeping",
                    "dead"
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Configure X-Ray daemon with enhanced settings
cat > /etc/amazon/xray/cfg.yaml << 'EOF'
TotalBufferSizeInMB: 0
Concurrency: 8
Region: us-east-1
Socket:
  UDPAddress: "0.0.0.0:2000"
  TCPAddress: "0.0.0.0:2000"
LocalMode: false
ResourceARN: ""
RoleARN: ""
NoVerifySSL: false
ProxyAddress: ""
DaemonAddress: "xray-daemon:2000"
LogLevel: prod
LogPath: "/var/log/xray/xray.log"
EOF

# Create log directory for X-Ray
mkdir -p /var/log/xray
chown xray:xray /var/log/xray

# Start X-Ray daemon
systemctl enable xray
systemctl start xray

# Ensure SSM agent is running
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Create nginx log directories
mkdir -p /var/log/nginx

# Install additional monitoring tools
yum install -y htop iotop stress-ng

# Create a simple X-Ray tracing test script
cat > /opt/test-xray.sh << 'EOF'
#!/bin/bash
echo "Testing X-Ray tracing..."

# Install AWS X-Ray SDK for testing
pip3 install aws-xray-sdk

# Create a simple Python script to generate traces
cat > /tmp/xray_test.py << 'PYTHON_EOF'
import time
import random
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch all AWS SDK calls
patch_all()

@xray_recorder.capture('test_function')
def test_function():
    # Simulate some work
    time.sleep(random.uniform(0.1, 0.5))
    
    # Simulate a subsegment
    subsegment = xray_recorder.begin_subsegment('database_query')
    time.sleep(random.uniform(0.05, 0.2))
    xray_recorder.end_subsegment()
    
    return "Test completed"

# Configure X-Ray
xray_recorder.configure(
    context_missing='LOG_ERROR',
    plugins=('EC2Plugin',),
    daemon_address='127.0.0.1:2000'
)

# Generate some traces
for i in range(5):
    with xray_recorder.in_segment('nginx_test_trace'):
        result = test_function()
        print(f"Trace {i+1}: {result}")
        time.sleep(1)

print("X-Ray test traces generated")
PYTHON_EOF

python3 /tmp/xray_test.py
EOF

chmod +x /opt/test-xray.sh

# Signal that the instance is ready
echo "Enhanced user data script completed successfully"
