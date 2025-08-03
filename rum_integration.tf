# Create an S3 bucket for hosting RUM integration files
resource "aws_s3_bucket" "rum_assets" {
  bucket = "nginx-rum-assets-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "nginx-rum-assets"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "rum_assets_pab" {
  bucket = aws_s3_bucket.rum_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "rum_assets_policy" {
  bucket = aws_s3_bucket.rum_assets.id
  depends_on = [aws_s3_bucket_public_access_block.rum_assets_pab]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.rum_assets.arn}/*"
      }
    ]
  })
}

# Upload RUM-integrated HTML file
resource "aws_s3_object" "rum_index" {
  bucket = aws_s3_bucket.rum_assets.id
  key    = "index.html"
  content_type = "text/html"

  content = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitored Nginx Application with RUM</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .metrics { 
            background: rgba(255,255,255,0.2); 
            padding: 20px; 
            border-radius: 10px; 
            margin: 20px 0; 
        }
        .status { 
            color: #4ade80; 
            font-weight: bold; 
            font-size: 1.2em;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .card {
            background: rgba(255,255,255,0.15);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255,255,255,0.2);
        }
        .btn {
            background: #4ade80;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
            transition: background 0.3s;
        }
        .btn:hover {
            background: #22c55e;
        }
        .performance-metrics {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
        .metric-value {
            font-size: 1.5em;
            font-weight: bold;
            color: #4ade80;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Advanced Monitored Nginx Application</h1>
        <div class="status">Status: Running with Full Observability Stack</div>
        
        <div class="grid">
            <div class="card">
                <h3>📊 CloudWatch Monitoring</h3>
                <ul>
                    <li>Real-time CPU, Memory, Disk metrics</li>
                    <li>Network throughput monitoring</li>
                    <li>Custom CloudWatch Dashboard</li>
                    <li>Proactive alerting via SNS</li>
                </ul>
            </div>
            
            <div class="card">
                <h3>👥 Real User Monitoring (RUM)</h3>
                <ul>
                    <li>Page load performance tracking</li>
                    <li>User interaction monitoring</li>
                    <li>Error tracking and reporting</li>
                    <li>Session replay capabilities</li>
                </ul>
            </div>
            
            <div class="card">
                <h3>🔍 X-Ray Tracing</h3>
                <ul>
                    <li>Request tracing and latency analysis</li>
                    <li>Service map visualization</li>
                    <li>Performance bottleneck identification</li>
                    <li>Distributed tracing support</li>
                </ul>
            </div>
        </div>
        
        <div class="metrics">
            <h3>🎯 Interactive Testing</h3>
            <p>Test different user journeys to generate monitoring data:</p>
            <button class="btn" onclick="simulatePageLoad()">Simulate Page Load</button>
            <button class="btn" onclick="simulateApiCall()">Test API Call</button>
            <button class="btn" onclick="simulateError()">Generate Error</button>
            <button class="btn" onclick="checkHealth()">Health Check</button>
        </div>
        
        <div class="performance-metrics">
            <h3>⚡ Real-time Performance Metrics</h3>
            <div id="performance-data">
                <div>Page Load Time: <span class="metric-value" id="load-time">Calculating...</span></div>
                <div>DOM Ready: <span class="metric-value" id="dom-ready">Calculating...</span></div>
                <div>First Paint: <span class="metric-value" id="first-paint">Calculating...</span></div>
            </div>
        </div>
        
        <div class="metrics">
            <h3>🔗 Monitoring Endpoints</h3>
            <p><strong>Health Check:</strong> <a href="/health" style="color: #4ade80;">/health</a></p>
            <p><strong>Nginx Status:</strong> <a href="/nginx_status" style="color: #4ade80;">/nginx_status</a></p>
            <p><strong>CloudWatch Dashboard:</strong> Check AWS Console</p>
        </div>
        
        <div class="metrics">
            <h3>📈 Monitoring Stack</h3>
            <div class="grid">
                <div>✅ CloudWatch Agent</div>
                <div>✅ X-Ray Daemon</div>
                <div>✅ RUM Integration</div>
                <div>✅ Enhanced Logging</div>
                <div>✅ Custom Metrics</div>
                <div>✅ Alerting System</div>
            </div>
        </div>
        
        <p><em>Deployed with Terraform + Enhanced Monitoring + Full Observability</em></p>
    </div>

    <!-- CloudWatch RUM Integration -->
    <script>
        (function(n,i,v,r,s,c,x,z){x=window.AwsRumClient={q:[],n:n,i:i,v:v,r:r,c:c};window[n]=function(c,p){x.q.push({c:c,p:p});};z=document.createElement('script');z.async=true;z.src=s;document.head.appendChild(z);})(
            'cwr',
            '${aws_rum_app_monitor.nginx_rum.app_monitor_id}',
            '1.0.0',
            'us-east-1',
            'https://client.rum.us-east-1.amazonaws.com/1.0.2/cwr.js',
            {
                sessionSampleRate: 1.0,
                guestRoleArn: "${aws_iam_role.rum_unauth_role.arn}",
                identityPoolId: "${aws_cognito_identity_pool.rum_identity_pool.id}",
                endpoint: "https://dataplane.rum.us-east-1.amazonaws.com",
                telemetries: ["performance","errors","http"],
                allowCookies: true,
                enableXRay: true
            }
        );

        // Custom RUM events
        function simulatePageLoad() {
            cwr('recordPageView', {
                pageId: 'test-page-load',
                pageTags: { testType: 'simulated-load' }
            });
            alert('Page load event recorded in RUM!');
        }

        function simulateApiCall() {
            fetch('/health')
                .then(response => {
                    cwr('recordEvent', {
                        name: 'api_call_success',
                        details: { endpoint: '/health', status: response.status }
                    });
                    alert('API call successful and recorded in RUM!');
                })
                .catch(error => {
                    cwr('recordError', {
                        name: 'api_call_error',
                        message: error.message
                    });
                });
        }

        function simulateError() {
            cwr('recordError', {
                name: 'simulated_error',
                message: 'This is a test error for monitoring',
                stack: 'Test stack trace'
            });
            alert('Error event recorded in RUM!');
        }

        function checkHealth() {
            fetch('/health')
                .then(response => response.text())
                .then(data => {
                    alert('Health check: ' + data);
                    cwr('recordEvent', {
                        name: 'health_check',
                        details: { status: 'healthy' }
                    });
                });
        }

        // Performance monitoring
        window.addEventListener('load', function() {
            setTimeout(function() {
                const perfData = performance.getEntriesByType('navigation')[0];
                if (perfData) {
                    document.getElementById('load-time').textContent = Math.round(perfData.loadEventEnd - perfData.fetchStart) + 'ms';
                    document.getElementById('dom-ready').textContent = Math.round(perfData.domContentLoadedEventEnd - perfData.fetchStart) + 'ms';
                }
                
                const paintEntries = performance.getEntriesByType('paint');
                const firstPaint = paintEntries.find(entry => entry.name === 'first-paint');
                if (firstPaint) {
                    document.getElementById('first-paint').textContent = Math.round(firstPaint.startTime) + 'ms';
                }
                
                // Record custom performance metrics
                cwr('recordEvent', {
                    name: 'page_performance',
                    details: {
                        loadTime: Math.round(perfData.loadEventEnd - perfData.fetchStart),
                        domReady: Math.round(perfData.domContentLoadedEventEnd - perfData.fetchStart),
                        firstPaint: firstPaint ? Math.round(firstPaint.startTime) : null
                    }
                });
            }, 1000);
        });

        // Track user interactions
        document.addEventListener('click', function(e) {
            if (e.target.tagName === 'BUTTON') {
                cwr('recordEvent', {
                    name: 'button_click',
                    details: { buttonText: e.target.textContent }
                });
            }
        });
    </script>
</body>
</html>
EOF

  tags = {
    Name        = "rum-integrated-index"
    Environment = var.environment
  }
}

# IAM role for RUM unauthenticated access
resource "aws_iam_role" "rum_unauth_role" {
  name = "RUM-Unauth-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.rum_identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "RUM-Unauth-Role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "rum_unauth_policy" {
  name = "RUM-Unauth-Policy"
  role = aws_iam_role.rum_unauth_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rum:PutRumEvents"
        ]
        Resource = aws_rum_app_monitor.nginx_rum.arn
      }
    ]
  })
}

# Cognito Identity Pool for RUM
resource "aws_cognito_identity_pool" "rum_identity_pool" {
  identity_pool_name               = "nginx_rum_identity_pool"
  allow_unauthenticated_identities = true

  tags = {
    Name        = "nginx-rum-identity-pool"
    Environment = var.environment
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "rum_roles" {
  identity_pool_id = aws_cognito_identity_pool.rum_identity_pool.id

  roles = {
    "unauthenticated" = aws_iam_role.rum_unauth_role.arn
  }
}
