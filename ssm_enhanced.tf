# Enhanced SSM Document for Docker Installation with monitoring
resource "aws_ssm_document" "install_docker_enhanced" {
  name          = "InstallDockerEnhanced"
  document_type = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Install Docker with enhanced monitoring and logging
parameters:
  logLevel:
    type: String
    description: Log level for Docker daemon
    default: info
    allowedValues:
      - debug
      - info
      - warn
      - error
mainSteps:
  - action: aws:runShellScript
    name: installDocker
    inputs:
      timeoutSeconds: '600'
      runCommand:
        - |
          #!/bin/bash
          set -e
          
          echo "Starting Docker installation with enhanced monitoring..."
          
          # Install Docker
          yum update -y
          yum install -y docker
          
          # Configure Docker daemon with logging
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
          
          # Start and enable Docker
          systemctl start docker
          systemctl enable docker
          
          # Add ec2-user to docker group
          usermod -a -G docker ec2-user
          
          # Install Docker Compose
          curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          
          # Create log file for Docker operations
          touch /var/log/docker.log
          chmod 644 /var/log/docker.log
          
          echo "Docker installation completed successfully"
          docker --version
          docker-compose --version
DOC

  tags = {
    Name = "InstallDockerEnhanced"
    Environment = var.environment
  }
}

# Enhanced SSM Document for Nginx Deployment with monitoring
resource "aws_ssm_document" "deploy_nginx_enhanced" {
  name          = "DeployNginxContainerEnhanced"
  document_type = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Deploy Nginx container with enhanced monitoring and custom configuration
parameters:
  nginxImage:
    type: String
    description: Nginx Docker image to use
    default: nginx:latest
  containerName:
    type: String
    description: Name for the Nginx container
    default: nginx-app
mainSteps:
  - action: aws:runShellScript
    name: deployNginx
    inputs:
      timeoutSeconds: '300'
      runCommand:
        - |
          #!/bin/bash
          set -e
          
          echo "Starting enhanced Nginx deployment..."
          
          # Stop and remove existing container if it exists
          docker stop nginx-app 2>/dev/null || true
          docker rm nginx-app 2>/dev/null || true
          
          # Create custom nginx configuration with logging
          mkdir -p /opt/nginx/conf
          cat > /opt/nginx/conf/nginx.conf << 'EOF'
          events {
              worker_connections 1024;
          }
          
          http {
              include       /etc/nginx/mime.types;
              default_type  application/octet-stream;
              
              # Enhanced logging format
              log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                             '$status $body_bytes_sent "$http_referer" '
                             '"$http_user_agent" "$http_x_forwarded_for" '
                             'rt=$request_time uct="$upstream_connect_time" '
                             'uht="$upstream_header_time" urt="$upstream_response_time"';
              
              access_log /var/log/nginx/access.log main;
              error_log /var/log/nginx/error.log warn;
              
              sendfile on;
              keepalive_timeout 65;
              
              # Enable gzip compression
              gzip on;
              gzip_vary on;
              gzip_min_length 1024;
              gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
              
              server {
                  listen 80;
                  server_name _;
                  
                  # Health check endpoint
                  location /health {
                      access_log off;
                      return 200 "healthy\n";
                      add_header Content-Type text/plain;
                  }
                  
                  # Metrics endpoint for monitoring
                  location /nginx_status {
                      stub_status on;
                      access_log off;
                      allow 127.0.0.1;
                      allow 10.0.0.0/8;
                      deny all;
                  }
                  
                  location / {
                      root /usr/share/nginx/html;
                      index index.html index.htm;
                      
                      # Add response time header
                      add_header X-Response-Time $request_time;
                  }
                  
                  # Custom error pages
                  error_page 404 /404.html;
                  error_page 500 502 503 504 /50x.html;
              }
          }
          EOF
          
          # Create custom index page with monitoring info
          mkdir -p /opt/nginx/html
          cat > /opt/nginx/html/index.html << 'EOF'
          <!DOCTYPE html>
          <html>
          <head>
              <title>Monitored Nginx Application</title>
              <style>
                  body { font-family: Arial, sans-serif; margin: 40px; }
                  .container { max-width: 800px; margin: 0 auto; }
                  .metrics { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
                  .status { color: green; font-weight: bold; }
              </style>
              <script>
                  // Simple performance monitoring
                  window.addEventListener('load', function() {
                      var loadTime = window.performance.timing.domContentLoadedEventEnd - window.performance.timing.navigationStart;
                      console.log('Page load time: ' + loadTime + 'ms');
                      
                      // Send custom metric (in real app, you'd send this to your monitoring service)
                      if (window.performance && window.performance.mark) {
                          window.performance.mark('page-loaded');
                      }
                  });
              </script>
          </head>
          <body>
              <div class="container">
                  <h1>🚀 Monitored Nginx Application</h1>
                  <div class="status">Status: Running with Enhanced Monitoring</div>
                  
                  <div class="metrics">
                      <h3>📊 Monitoring Features</h3>
                      <ul>
                          <li>CloudWatch Dashboard with CPU, Memory, Disk, Network metrics</li>
                          <li>CloudWatch Alarms for proactive monitoring</li>
                          <li>Real User Monitoring (RUM) for user experience tracking</li>
                          <li>X-Ray tracing for application performance</li>
                          <li>Enhanced Nginx logging with response times</li>
                          <li>Health check endpoint: <a href="/health">/health</a></li>
                          <li>Nginx status: <a href="/nginx_status">/nginx_status</a></li>
                      </ul>
                  </div>
                  
                  <div class="metrics">
                      <h3>🔍 Monitoring Endpoints</h3>
                      <p><strong>Health Check:</strong> <code>curl http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health</code></p>
                      <p><strong>Nginx Status:</strong> <code>curl http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)/nginx_status</code></p>
                  </div>
                  
                  <p><em>Deployed with Terraform + SSM + Enhanced Monitoring</em></p>
              </div>
          </body>
          </html>
          EOF
          
          # Create log directories
          mkdir -p /var/log/nginx
          
          # Deploy Nginx container with enhanced configuration
          docker run -d \
            --name nginx-app \
            --restart unless-stopped \
            -p 80:80 \
            -v /opt/nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro \
            -v /opt/nginx/html:/usr/share/nginx/html:ro \
            -v /var/log/nginx:/var/log/nginx \
            nginx:latest
          
          # Wait for container to be ready
          sleep 5
          
          # Test the deployment
          if curl -f http://localhost/health > /dev/null 2>&1; then
            echo "✅ Nginx deployment successful - health check passed"
            docker ps | grep nginx-app
          else
            echo "❌ Nginx deployment failed - health check failed"
            docker logs nginx-app
            exit 1
          fi
          
          echo "Enhanced Nginx deployment completed successfully"
DOC

  tags = {
    Name = "DeployNginxContainerEnhanced"
    Environment = var.environment
  }
}

# Enhanced SSM Associations
resource "aws_ssm_association" "install_docker_enhanced" {
  name = aws_ssm_document.install_docker_enhanced.name

  targets {
    key    = "tag:SSMManaged"
    values = ["true"]
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_output_bucket.bucket
    s3_key_prefix  = "docker-installation-enhanced/"
  }

  parameters = {
    logLevel = "info"
  }

  tags = {
    Name = "install-docker-enhanced"
    Environment = var.environment
  }
}

resource "aws_ssm_association" "deploy_nginx_enhanced" {
  name = aws_ssm_document.deploy_nginx_enhanced.name

  # Run after Docker installation
  depends_on = [aws_ssm_association.install_docker_enhanced]

  targets {
    key    = "tag:DockerHost"
    values = ["true"]
  }

  # Schedule to run every 30 minutes to ensure container is running
  schedule_expression = "rate(30 minutes)"
  max_concurrency    = "1"
  max_errors         = "0"

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_output_bucket.bucket
    s3_key_prefix  = "nginx-deployment-enhanced/"
  }

  parameters = {
    nginxImage    = "nginx:latest"
    containerName = "nginx-app"
  }

  tags = {
    Name        = "deploy-nginx-enhanced"
    Environment = var.environment
  }
}

# SSM Document for Demo Tools and Testing
resource "aws_ssm_document" "setup_demo_tools" {
  name          = "SetupDemoTools"
  document_type = "Command"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '2.2'
description: Setup demo tools for stress testing and latency simulation
mainSteps:
  - action: aws:runShellScript
    name: setupDemoTools
    inputs:
      timeoutSeconds: '300'
      runCommand:
        - |
          #!/bin/bash
          set -e
          
          echo "=== Setting up demo tools ==="
          
          # Install stress testing tools
          yum install -y stress-ng htop iotop
          
          # Create latency simulation endpoints
          mkdir -p /opt/nginx/html/api
          
          # Create slow endpoint that takes 2-5 seconds
          cat > /opt/nginx/html/api/slow.html << 'EOF'
          <!DOCTYPE html>
          <html>
          <head>
              <title>Slow Endpoint</title>
              <script>
                  // Simulate slow loading
                  setTimeout(function() {
                      document.getElementById('content').innerHTML = 'Slow content loaded after delay!';
                  }, 3000);
              </script>
          </head>
          <body>
              <h1>Slow Loading Endpoint</h1>
              <div id="content">Loading... (this takes 3 seconds)</div>
              <p>This endpoint simulates slow response times for monitoring demos.</p>
          </body>
          </html>
          EOF
          
          # Create error simulation endpoint
          cat > /opt/nginx/html/api/error.html << 'EOF'
          <!DOCTYPE html>
          <html>
          <head>
              <title>Error Simulation</title>
              <script>
                  // Randomly generate errors for demo
                  if (Math.random() < 0.3) {
                      throw new Error('Simulated client-side error for monitoring demo');
                  }
              </script>
          </head>
          <body>
              <h1>Error Simulation Endpoint</h1>
              <p>This endpoint randomly generates errors for monitoring demos.</p>
              <p>Refresh the page multiple times to trigger errors.</p>
          </body>
          </html>
          EOF
          
          # Create test endpoint with RUM integration
          cat > /opt/nginx/html/api/test.html << 'EOF'
          <!DOCTYPE html>
          <html>
          <head>
              <title>Test Endpoint with RUM</title>
              <script>
                  // Enhanced RUM tracking
                  window.addEventListener('load', function() {
                      // Simulate user interactions for RUM
                      setTimeout(function() {
                          console.log('User interaction simulated');
                          // In real app, this would trigger RUM events
                      }, 1000);
                  });
              </script>
          </head>
          <body>
              <h1>Test Endpoint</h1>
              <p>This endpoint is optimized for RUM monitoring.</p>
              <button onclick="console.log('Button clicked - RUM event')">Test Button</button>
          </body>
          </html>
          EOF
          
          # Create stress test scripts
          cat > /opt/stress-cpu.sh << 'EOF'
          #!/bin/bash
          echo "Starting CPU stress test for 5 minutes..."
          stress-ng --cpu 2 --timeout 300s --metrics-brief
          echo "CPU stress test completed"
          EOF
          
          cat > /opt/stress-memory.sh << 'EOF'
          #!/bin/bash
          echo "Starting Memory stress test for 3 minutes..."
          stress-ng --vm 1 --vm-bytes 512M --timeout 180s --metrics-brief
          echo "Memory stress test completed"
          EOF
          
          cat > /opt/generate-traffic.sh << 'EOF'
          #!/bin/bash
          echo "Generating web traffic for monitoring demo..."
          
          # Get the local IP
          LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
          
          # Generate normal traffic
          for i in {1..20}; do
              curl -s http://$LOCAL_IP/ > /dev/null
              curl -s http://$LOCAL_IP/health > /dev/null
              sleep 1
          done
          
          # Generate slow requests
          for i in {1..5}; do
              curl -s http://$LOCAL_IP/api/slow.html > /dev/null &
              sleep 2
          done
          
          # Generate some errors (404s)
          for i in {1..10}; do
              curl -s http://$LOCAL_IP/nonexistent-page > /dev/null
              sleep 1
          done
          
          echo "Traffic generation completed"
          EOF
          
          # Make scripts executable
          chmod +x /opt/stress-*.sh /opt/generate-traffic.sh
          
          # Restart nginx container to pick up new files
          docker restart nginx-app || true
          
          echo "=== Demo tools setup completed ==="
          echo "Available tools:"
          echo "  - /opt/stress-cpu.sh (CPU stress test)"
          echo "  - /opt/stress-memory.sh (Memory stress test)"
          echo "  - /opt/generate-traffic.sh (Web traffic generation)"
          echo "  - http://your-ip/api/slow.html (Slow endpoint)"
          echo "  - http://your-ip/api/error.html (Error simulation)"
          echo "  - http://your-ip/api/test.html (RUM test endpoint)"
DOC

  tags = {
    Name        = "SetupDemoTools"
    Environment = var.environment
  }
}

# SSM Association for demo tools
resource "aws_ssm_association" "setup_demo_tools" {
  name = aws_ssm_document.setup_demo_tools.name

  depends_on = [aws_ssm_association.deploy_nginx_enhanced]

  targets {
    key    = "tag:DockerHost"
    values = ["true"]
  }

  output_location {
    s3_bucket_name = aws_s3_bucket.ssm_output_bucket.bucket
    s3_key_prefix  = "demo-tools-setup/"
  }

  tags = {
    Name        = "setup-demo-tools"
    Environment = var.environment
  }
}
