# Complete Architecture Diagram - Docker Nginx EC2 Monitoring Demo

## High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                             │
└─────────────────────────────────────┬───────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                  AWS CLOUD                                             │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              VPC (10.0.0.0/16)                                 │   │
│  │                                                                                 │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                    Public Subnet (10.0.1.0/24)                         │   │   │
│  │  │                                                                         │   │   │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │   │   │
│  │  │  │                    EC2 Instance (t2.micro)                      │   │   │   │
│  │  │  │                                                                 │   │   │   │
│  │  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │   │   │
│  │  │  │  │ CloudWatch  │  │   X-Ray     │  │     SSM     │            │   │   │   │
│  │  │  │  │   Agent     │  │   Daemon    │  │   Agent     │            │   │   │   │
│  │  │  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │   │   │
│  │  │  │                                                                 │   │   │   │
│  │  │  │  ┌─────────────────────────────────────────────────────────┐   │   │   │   │
│  │  │  │  │                Docker Engine                            │   │   │   │   │
│  │  │  │  │                                                         │   │   │   │   │
│  │  │  │  │  ┌─────────────────────────────────────────────────┐   │   │   │   │   │
│  │  │  │  │  │              Nginx Container                    │   │   │   │   │   │
│  │  │  │  │  │                                                 │   │   │   │   │   │
│  │  │  │  │  │  • Port 80 (HTTP)                              │   │   │   │   │   │
│  │  │  │  │  │  • Health Check (/health)                      │   │   │   │   │   │
│  │  │  │  │  │  • Status Endpoint (/nginx_status)             │   │   │   │   │   │
│  │  │  │  │  │  • Enhanced Logging                            │   │   │   │   │   │
│  │  │  │  │  │  • RUM Integration                             │   │   │   │   │   │
│  │  │  │  │  └─────────────────────────────────────────────────┘   │   │   │   │   │
│  │  │  │  └─────────────────────────────────────────────────────────┘   │   │   │   │
│  │  │  └─────────────────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                           MONITORING & OBSERVABILITY                           │   │
│  │                                                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │   │
│  │  │ CloudWatch  │  │ CloudWatch  │  │    X-Ray    │  │    RUM      │          │   │
│  │  │ Dashboard   │  │   Alarms    │  │   Tracing   │  │ Monitoring  │          │   │
│  │  │             │  │             │  │             │  │             │          │   │
│  │  │ • CPU       │  │ • High CPU  │  │ • Request   │  │ • Page Load │          │   │
│  │  │ • Memory    │  │ • Memory    │  │   Traces    │  │ • User      │          │   │
│  │  │ • Disk      │  │ • Disk      │  │ • Service   │  │   Journey   │          │   │
│  │  │ • Network   │  │ • Status    │  │   Map       │  │ • Errors    │          │   │
│  │  │ • Logs      │  │ • Custom    │  │ • Latency   │  │ • Custom    │          │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘          │   │
│  │                                                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │   │
│  │  │ CloudWatch  │  │     S3      │  │   Cognito   │  │ Synthetics  │          │   │
│  │  │    Logs     │  │   Buckets   │  │ Identity    │  │   Canary    │          │   │
│  │  │             │  │             │  │    Pool     │  │             │          │   │
│  │  │ • System    │  │ • SSM       │  │             │  │ • Health    │          │   │
│  │  │ • Docker    │  │   Outputs   │  │ • RUM       │  │   Checks    │          │   │
│  │  │ • Nginx     │  │ • RUM       │  │   Auth      │  │ • User      │          │   │
│  │  │ • X-Ray     │  │   Assets    │  │             │  │   Journey   │          │   │
│  │  │ • Custom    │  │ • Synthetics│  │             │  │ • E2E Tests │          │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              ALERTING & NOTIFICATIONS                          │   │
│  │                                                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │   │
│  │  │     SNS     │  │   Email     │  │    Slack    │  │  PagerDuty  │          │   │
│  │  │    Topic    │  │   Alerts    │  │ Integration │  │ Integration │          │   │
│  │  │             │  │             │  │ (Optional)  │  │ (Optional)  │          │   │
│  │  │ • High CPU  │  │ • Admin     │  │             │  │             │          │   │
│  │  │ • Memory    │  │   Team      │  │             │  │             │          │   │
│  │  │ • Disk      │  │             │  │             │  │             │          │   │
│  │  │ • Errors    │  │             │  │             │  │             │          │   │
│  │  │ • Health    │  │             │  │             │  │             │          │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘          │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Detailed Component Flow Diagram

### 1. User Request Flow
```
User Browser ──HTTP GET──▶ Internet Gateway ──▶ Route Table ──▶ Security Group ──▶ EC2 Instance
                                                                                        │
                                                                                        ▼
                                                                                 Docker Engine
                                                                                        │
                                                                                        ▼
                                                                                Nginx Container
                                                                                        │
                                                                                        ▼
                                                                                 HTTP Response
```

### 2. Monitoring Data Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                EC2 INSTANCE                                            │
│                                                                                         │
│  Application Layer:                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                                │
│  │   Nginx     │───▶│   Access    │───▶│   Error     │                                │
│  │ Container   │    │    Logs     │    │    Logs     │                                │
│  └─────────────┘    └─────────────┘    └─────────────┘                                │
│                                                                                         │
│  System Layer:                                                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                                │
│  │ CloudWatch  │    │   X-Ray     │    │   System    │                                │
│  │   Agent     │    │   Daemon    │    │    Logs     │                                │
│  └─────────────┘    └─────────────┘    └─────────────┘                                │
│         │                   │                   │                                      │
│         ▼                   ▼                   ▼                                      │
└─────────┼───────────────────┼───────────────────┼──────────────────────────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              AWS SERVICES                                              │
│                                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │
│  │ CloudWatch  │    │    X-Ray    │    │ CloudWatch  │    │     RUM     │            │
│  │   Metrics   │    │   Service   │    │    Logs     │    │   Events    │            │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘            │
│         │                   │                   │                   │                  │
│         ▼                   ▼                   ▼                   ▼                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │
│  │ CloudWatch  │    │   Service   │    │   Insights  │    │   User      │            │
│  │ Dashboard   │    │     Map     │    │   Queries   │    │ Experience  │            │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘            │
│         │                   │                   │                   │                  │
│         ▼                   ▼                   ▼                   ▼                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │
│  │ CloudWatch  │    │   Latency   │    │    Log      │    │   Custom    │            │
│  │   Alarms    │    │  Analysis   │    │  Analysis   │    │   Events    │            │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 3. Terraform Resource Dependency Graph
```
Data Sources (AMI, AZs, Caller Identity)
    │
    ▼
Random String (Bucket Suffix)
    │
    ▼
IAM Resources (Roles, Policies, Instance Profile)
    │
    ▼
VPC Resources (VPC, Subnet, IGW, Route Table, Security Group)
    │
    ▼
S3 Resources (SSM Output Bucket, RUM Assets Bucket, Synthetics Bucket)
    │
    ▼
CloudWatch Resources (Log Group, Dashboard, Alarms, Queries)
    │
    ▼
SSM Resources (Documents, Associations)
    │
    ▼
EC2 Instance (with User Data)
    │
    ▼
Monitoring Resources (RUM, X-Ray, Cognito, Synthetics)
    │
    ▼
SNS Resources (Topic, Subscriptions)
```

This architecture provides comprehensive monitoring across all layers of the application stack, from infrastructure to user experience.
