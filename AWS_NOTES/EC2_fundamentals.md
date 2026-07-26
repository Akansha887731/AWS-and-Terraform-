# **Amazon EC2 Fundamentals Notes**

## 1. Overview of Amazon EC2

- **What is EC2?**: Elastic Compute Cloud (EC2) is an **Infrastructure as a Service (IaaS)** offering that lets you rent virtual machines on demand in the AWS Cloud.
- **Core Capabilities**:
    - Renting virtual machines (**EC2**).
    - Storing data on virtual network/local drives (**EBS / Instance Store**).
    - Distributing load across instances (**Elastic Load Balancer - ELB**).
    - Automatically scaling compute resources (**Auto Scaling Group - ASG**).

## 2. Sizing & Configuration Options

When launching an EC2 instance, you configure:

- **Operating System (OS)**: Linux, Windows, or macOS.
- **Compute Power & Memory**: CPU cores and RAM capacity.
- **Storage Options**:
    - **Network-attached**: Amazon EBS (Elastic Block Store) and Amazon EFS.
    - **Hardware/Local**: EC2 Instance Store.
- **Networking**: Network card speed and Public/Private IP address assignment.
- **Firewall Rules**: Attached **Security Groups**.
- **Bootstrap Script**: **EC2 User Data**.

## 3. EC2 User Data (Bootstrapping)

- **Definition**: A script that executes **only once** at the instance's **first boot**.
- **Purpose**: Automates initial provisioning tasks (installing software, running updates, downloading configuration files).
- **Permissions**: Runs with **`root`** privileges.

### 💻 User Data Script Example

Bash

```
#!/bin/bash
# Update system packages
yum update -y

# Install Apache Web Server (httpd)
yum install -y httpd

# Start & enable web server service
systemctl start httpd
systemctl enable httpd

# Create simple home page with instance hostname
echo "<h1>Hello World from EC2 Instance: $(hostname -f)</h1>" > /var/www/html/index.html
```

## 4. EC2 Instance Types & Naming Conventions

AWS uses a standard naming convention for instance types (e.g., **`m5.2xlarge`**):

- **`m`**: Instance Class / Family.
- **`5`**: Generation (newer generations offer better performance/cost).
- **`2xlarge`**: Size within the instance family (determines CPU/RAM ratio).

### Instance Families & Use Cases

1. **General Purpose (e.g., `t2.micro`, `m5`)**:
    - Balanced ratio of Compute, Memory, and Networking.
    - *Use Cases*: Web servers, code repositories, development environments.
2. **Compute Optimized (e.g., `c5`)**:
    - High-performance processors for compute-intensive workloads.
    - *Use Cases*: Batch processing, media transcoding, scientific modeling, machine learning inference, gaming servers.
3. **Memory Optimized (e.g., `r5`)**:
    - Fast performance for processing large datasets in memory (RAM).
    - *Use Cases*: In-memory databases (Redis/Memcached), relational/NoSQL DBs, real-time data analytics.
4. **Storage Optimized (e.g., `i3`)**:
    - Optimized for low-latency, high sequential read/write access to large local storage.
    - *Use Cases*: High-frequency OLTP databases, NoSQL databases, data warehousing, distributed file systems.

## 5. Security Groups

Security Groups act as a **virtual firewall** controlling inbound and outbound network traffic for your EC2 instances.

### Key Characteristics:

- **Rules**: Contain **ALLOW rules only** (cannot define DENY rules).
- **Stateful**: If inbound traffic is allowed, outbound response traffic is automatically allowed.
- **Scope**: Bound to a specific Region / VPC.
- **External Firewall**: Operates outside the EC2 instance; blocked traffic never reaches the OS.
- **Defaults**:
    - **Inbound traffic**: Blocked by default.
    - **Outbound traffic**: Allowed by default.

### ⛓️ Security Group Chaining (Multi-Tier Security)

Instead of hardcoding IP addresses, security group rules can reference **other Security Groups** as their source.

- **Load Balancer SG (`sg-alb`)**:
    - **Inbound**: Allows HTTP/HTTPS (Ports 80/443) from `0.0.0.0/0` (Internet).
- **EC2 Web App SG (`sg-web`)**:
    - **Inbound**: Allows HTTP (Port 80) ONLY from `sg-alb`.
- **Database SG (`sg-db`)**:
    - **Inbound**: Allows DB Port (3306/5432) ONLY from `sg-web`.

### 🔍 Network Troubleshooting Rules of Thumb

- ⌛ **Connection Timeout**: Security Group misconfiguration or network firewall blocking traffic.
- ❌ **Connection Refused**: Application-level error (service is crashed or not listening on port).

## 6. EC2 Purchasing Options

| Purchasing Option | Key Features & Pricing Model | Ideal Use Case |
| --- | --- | --- |
| **On-Demand** | Pay-per-second or pay-per-hour. Highest cost, no commitment, no upfront fee. | Short-term, unpredictable, or non-interruptible workloads. |
| **Reserved Instances (RI)** | Up to 72% discount. 1 or 3-year commitment. Payment: No Upfront, Partial Upfront, All Upfront. | Steady-state, predictable usage applications. |
| **Convertible RIs** | Up to 66% discount. Allows changing instance family, OS, type, and tenancy. | Long-term workloads needing flexible hardware specifications. |
| **Savings Plans** | Up to 72% discount based on long-term hourly spend commitment ($/hr for 1 or 3 yrs). | Long-term usage with flexible instance size/OS needs. |
| **Spot Instances** | Up to 90% discount (cheapest option). Can be reclaimed by AWS with a 2-minute warning. | Fault-tolerant, stateless batch processing, data analysis, CI/CD pipelines. |
| **Dedicated Hosts** | Physical server fully dedicated to your account. Most expensive. | Strict compliance/regulatory requirements or BYOL per-socket/core software licenses. |
| **Dedicated Instances** | Hardware dedicated to your account (may share physical server with other instances in your account). | Hardware isolation requirements without host placement control. |
| **Capacity Reservations** | Reserve On-Demand instance capacity in a specific Availability Zone (AZ). | Short-term critical workloads requiring guaranteed AZ capacity. |

## 7. EC2 Instance Metadata Service (IMDS)

- **Purpose**: Allows EC2 instances to programmatically access information about themselves without hardcoding credentials or requiring AWS API access.
- **Metadata Base URL**: `http://169.254.169.254/latest/meta-data/`
- **Examples of Metadata Retrievable**:
    1. Public and Private IP addresses
    2. Instance ID and Instance Type
    3. Security group names
    4. Name of attached IAM Roles
    5. Temporary security credentials associated with the IAM Role
- **Metadata vs. User Data**:
    
    
    | **Feature** | **EC2 Instance Metadata** | **EC2 User Data** |
    | --- | --- | --- |
    | **Definition** | Information *about* the running instance (e.g., public/private IP, instance ID, attached IAM role name). | Initial configuration script provided during instance launch. |
    | **URL Path** | `http://169.254.169.254/latest/meta-data/` | `http://169.254.169.254/latest/user-data/` |
    | **Execution** | Passive data read via HTTP requests. | Executed automatically once during first boot with `root` privileges. |
- 📌 **Exam Note**: You can retrieve the IAM Role **name** via metadata, but **NOT** the underlying IAM Policy permissions.

### 💻 IMDSv1 vs. IMDSv2

AWS provides two methods for querying the Instance Metadata Service (IMDS): **IMDSv1** and **IMDSv2**.

### 🔹 IMDSv1 (Direct HTTP Request)

- **How it works**: Uses simple, unauthenticated HTTP `GET` requests sent directly to the metadata endpoint.
- **Security Risk**: Vulnerable to **Server-Side Request Forgery (SSRF)** attacks. If a web application hosted on the instance has an SSRF vulnerability, an attacker could force the application to fetch `http://169.254.169.254/latest/meta-data/` and expose temporary IAM role credentials.

Bash

```
# Get Instance ID
curl http://169.254.169.254/latest/meta-data/instance-id

# Get Private IP Address
curl http://169.254.169.254/latest/meta-data/local-ipv4

# Get Attached IAM Role Name
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

### 🔹 IMDSv2 (Session Token Required)

- **How it works**: Uses a **session-oriented protocol**. Every request requires a valid session token passed via an HTTP header.
- **Security Advantage**: Prevents SSRF attacks. SSRF attacks usually cannot construct arbitrary HTTP `PUT` requests with headers, so attackers cannot generate or pass the required token.

Bash

```
# Step 1: Generate a session token (valid for up to 6 hours / 21600 seconds)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
             -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use token in header to retrieve metadata
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
```

| **Feature** | **IMDSv1** | **IMDSv2** |
| --- | --- | --- |
| **Request Method** | Direct `GET` requests | `PUT` request for token, followed by `GET` request with header |
| **Authentication** | Unauthenticated | Session Token-based |
| **Security Level** | Less secure (vulnerable to SSRF) | High security (SSRF resistant) |
| **AWS Recommendation** | Legacy option | Best practice (AWS recommended) |