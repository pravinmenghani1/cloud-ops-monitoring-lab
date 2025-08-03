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
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent",
                    "inodes_free"
                ],
                "metrics_collection_interval": 60,
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
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent",
                    "mem_available_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
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

# Configure X-Ray daemon
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

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack $${AWS::StackName} --resource AutoScalingGroup --region $${AWS::Region} || true
