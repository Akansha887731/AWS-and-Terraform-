# ELB + ASG

# 📌 Elastic Load Balancing (ELB) & Auto Scaling Groups (ASG)

## Part 1: Elastic Load Balancing (ELB)

### 1. Fundamentals of ELB

- **What is a Load Balancer?**: A managed virtual or physical server that automatically distributes incoming application traffic across multiple backend targets (such as EC2 instances, containers, IP addresses, or Lambda functions).
- **Why Use an Elastic Load Balancer?**:
    - **High Availability**: Spreads load across multiple Availability Zones (AZs).
    - **Single Point of Entry**: Provides a single DNS name for client requests.
    - **Fault Tolerance**: Automatically runs health checks and routes around unhealthy instances.
    - **Managed Service**: AWS handles operation, maintenance, updates, and scaling with minimal configuration required.
    - **Deep AWS Integration**: Native integration with EC2, ASG, ECS, ACM (SSL certificates), CloudWatch, Route 53, WAF, and Global Accelerator.

### 2. Types of Load Balancers on AWS

AWS provides 4 types of managed load balancers:

| **Load Balancer Type** | **OSI Layer** | **Supported Protocols** | **Key Use Cases & Features** |
| --- | --- | --- | --- |
| **Application Load Balancer (ALB)** | **Layer 7** (Application) | HTTP, HTTPS, WebSocket | Path-based/Host-based routing, microservices, web apps, SSL termination. |
| **Network Load Balancer (NLB)** | **Layer 4** (Transport) | TCP, UDP, TLS | Ultra-low latency (milliseconds), static IP support (1 per AZ), high throughput. |
| **Gateway Load Balancer (GWLB)** | **Layer 3** (Network) | IP Protocol | Routes traffic through 3rd-party virtual network appliances (firewalls, IDS/IPS). |
| **Classic Load Balancer (CLB)** | Layer 4 & 7 | HTTP, HTTPS, TCP, SSL | **Legacy (v1)** — Not recommended for new workloads. |

> **Note**: Load balancers can be deployed as **Internal** (private IPs only) or **External** (Internet-facing public IPs).
> 

### 3. Key Operational Mechanisms

#### 🏥 Health Checks

- Sends periodic HTTP/TCP requests to downstream targets to test availability.
- If an instance returns an error (or non-200 HTTP code), the ELB marks it **Unhealthy** and stops sending traffic to it.

#### 📌 Stickiness (Session Affinity)

- Directs requests from the same user session consistently to the **same backend instance** using cookies.
- Can use **ELB-generated cookies** (`AWSALB`) or **Custom Application-generated cookies**.

#### 🌐 Cross-Zone Load Balancing

- Distributes traffic evenly across **all backend instances in all enabled AZs**, regardless of how many instances are in each individual AZ.
- Enabled by default for ALB; optional for NLB.

#### ⏳ Connection Draining (Deregistration Delay)

- Gives existing in-flight requests time to finish before an instance is fully detached/deregistered from the target group during maintenance or scale-in.
- Configurable delay range: **0 to 3600 seconds** (default: 300s).

### 4. ELB Architecture Diagram

```
Client / Internet
       │
       ▼ (DNS / Port 443)
┌─────────────────────────────────────────────────────────┐
│ Application Load Balancer (ALB)                         │
│ ├─ ACM (SSL Certificate Termination)                    │
│ └─ Listener Rule Engine                                 │
└───────────────────────────┬─────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼ (Path: /api)              ▼ (Path: /web)
    ┌───────────────────┐       ┌───────────────────┐
    │  Target Group A   │       │  Target Group B   │
    │ (Microservices)   │       │  (Web Frontends)  │
    └─────────┬─────────┘       └─────────┬─────────┘
              │                           │
    ┌─────────┴─────────┐       ┌─────────┴─────────┐
    │ Health Check:     │       │ Health Check:     │
    │ HTTP 200 /health  │       │ HTTP 200 /health  │
    └───────────────────┘       └───────────────────┘
```

## Part 2: Auto Scaling Groups (ASG)

### 1. Fundamentals of ASG

- **What is an Auto Scaling Group?**: A service that automatically adds (scales out) or removes (scales in) EC2 instances to handle workload changes while keeping costs minimal.
- **Core Functions**:
    - Automatically scales capacity to match demand.
    - Maintains **Minimum**, **Desired**, and **Maximum** instance limits.
    - Integrates with Load Balancers to register new instances automatically.
    - **Auto-healing**: Replaces terminated or unhealthy instances automatically.
- **Cost**: The ASG service itself is **completely free** — you only pay for the underlying EC2 instances and attached storage.

### 2. ASG Instance Capacity Attributes

ASG manages capacity based on three core parameters:

1. **Minimum Size**: Lower bound; ensures baseline availability.
2. **Desired Capacity**: Target number of instances running under standard conditions.
3. **Maximum Size**: Upper bound; prevents runaway costs during sudden demand surges.

### 3. Scaling Strategies & Policies

- **Target Tracking Scaling**: Maintains a specific metric at a defined target value (e.g., keep average CPU utilization at 60%).
- **Simple / Step Scaling**:
    - *Simple*: Adds/removes a fixed number of instances when a CloudWatch alarm threshold is met (e.g., CPU > 80% $\rightarrow$ add 2 instances).
    - *Step*: Scales proportionally based on the size of the metric breach.
- **Scheduled Scaling**: Adjusts capacity based on predictable traffic schedules (e.g., scale up every Monday morning).
- **Predictive Scaling**: Uses machine learning models to analyze historic load and scale ahead of anticipated traffic.

### 4. Advanced ASG Features

- **Launch Templates**: Modern blueprint defining EC2 instance configuration (AMI, instance types, security groups, user data scripts). Supports versioning and mixing On-Demand with Spot instances.
- **Lifecycle Hooks**: Pauses instances during scale-out or scale-in states so custom actions (e.g., running setup scripts or dumping log files) can execute before completion.
- **ASG Cooldown Period**: A mandatory pause (default: 300 seconds) after scaling activity to allow new instances to stabilize before launching or terminating more.

### 5. ASG Architecture Diagram

```
                     ┌───────────────────────────────┐
                     │    CloudWatch Alarm           │
                     │  (e.g., CPU Usage > 80%)      │
                     └───────────────┬───────────────┘
                                     │ Trigger Scale Out
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Auto Scaling Group (ASG)                                               │
│                                                                        │
│  Capacity Targets: [ Min: 2  |  Desired: 3  |  Max: 10 ]               │
│                                                                        │
│  ┌─────────────────────────┐               ┌─────────────────────────┐ │
│  │ EC2 Instance (AZ-1a)    │               │ EC2 Instance (AZ-1b)    │ │
│  │ Status: Healthy         │               │ Status: Healthy         │ │
│  └────────────┬────────────┘               └────────────┬────────────┘ │
│               │                                         │              │
│               └───────────────────┬─────────────────────┘              │
│                                   │ Auto-Provision                     │
│                                   ▼                                    │
│                        ┌─────────────────────┐                         │
│                        │ EC2 Instance (AZ-1c)│ <── (Newly Launched)     │
│                        └──────────┬──────────┘                         │
└───────────────────────────────────┼────────────────────────────────────┘
                                    │ Auto-Register
                                    ▼
                     ┌───────────────────────────────┐
                     │   Target Group / ELB          │
                     └───────────────────────────────┘
```

## Part 3: AWS CLI Practical Implementation Code

### 1. Create an ALB and Target Group

```
# 1. Create an Application Load Balancer
aws elbv2 create-load-balancer \
  --name my-web-alb \
  --subnets subnet-12345678 subnet-87654321 \
  --security-groups sg-11223344 \
  --scheme internet-facing \
  --type application

# 2. Create a Target Group with Health Check on HTTP Port 80
aws elbv2 create-target-group \
  --name my-web-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-1a2b3c4d \
  --health-check-protocol HTTP \
  --health-check-port 80 \
  --health-check-path /health \
  --health-check-interval-seconds 30
```

### 2. Create an ASG Attached to the Target Group

### Create Auto Scaling Group attached to Target Group

```
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name my-asg \
  --launch-template LaunchTemplateId=lt-0123456789abcdef0,Version='$Default' \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 2 \
  --vpc-zone-identifier "subnet-12345678,subnet-87654321" \
  --target-group-arns arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-web-targets/1234567890 \
  --health-check-type ELB \
  --health-check-grace-period 300
```
