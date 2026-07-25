# IAM and AWS CLI

## 🔑 Part 1: AWS IAM Essentials

### Core Definitions

- **IAM**: A global service used to manage access to AWS resources securely.
- **Root Account**: Created by default when the account is opened. **Best practice**: Do not use or share it for daily tasks.
- **Users**: Mapped to a single physical individual/person.
- **Groups**: Contain users only (cannot contain other groups). Users do not *have* to belong to a group and can belong to multiple groups.
- **Roles**: Assigned to AWS services (e.g., EC2, Lambda) or federated users to perform actions on your behalf.

!image.png

### IAM Policies Structure

JSON documents defining what actions are allowed or denied on specific resources following the **Principle of Least Privilege**.

### Policy JSON Structure Key Elements:

- **`Version`**: Policy language version. Always use `"2012-10-17"`.
- **`Id`**: Optional policy identifier.
- **`Statement`**: Array of required individual statements.
    - **`Sid`**: Statement ID (optional).
    - **`Effect`**: `Allow` or `Deny`.
    - **`Principal`**: Account, user, or role to which the policy applies (used in resource-based or trust policies).
    - **`Action`**: List of API actions allowed/denied (e.g., `s3:GetObject`).
    - **`Resource`**: List of AWS resources (ARNs) the actions apply to.
    - **`Condition`**: Optional criteria under which the policy applies.

JSON

```
{
  "Version": "2012-10-17",
  "Id": "S3-Account-Permissions",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Principal": {
        "AWS": ["arn:aws:iam::123456789012:root"]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": ["arn:aws:s3:::mybucket/*"]
    }
  ]
}
```

### Password Policy & MFA

- **Password Policy**: Sets minimum lengths, character types, password expiration, and prevents re-use.
- **MFA (Multi-Factor Authentication)**: Combines a known password with a physical or virtual security device.
    - **Options**: Virtual MFA (Google Authenticator, Authy), U2F / Security Keys (YubiKey), Hardware Key Fobs (Gemalto / SurePassID).

### Audit & Security Tools

- **IAM Credentials Report** *(Account-level)*: Lists all account users and the status of their credentials.
- **IAM Access Advisor** *(User-level)*: Displays granted permissions and when they were last accessed to help refine permissions.
- **IAM Access Analyzer**: Identifies resources shared externally outside the defined zone of trust.

## 🛠️ Part 2: AWS CLI, SDK, IAM Roles & Policies

### Accessing AWS Programmatically

Users can access AWS via:

1. **AWS Management Console**: Password + MFA.
2. **AWS Command Line Interface (CLI)**: Command-line tool using Access Keys.
3. **AWS Software Development Kit (SDK)**: Code-level access using Access Keys or IAM Roles.

### Access Keys:

- **Access Key ID** $\approx$ Username
- **Secret Access Key** $\approx$ Password

> **Important**: Never embed access keys directly into code or commit them to public version control repositories!
> 

### IAM Roles for Services

Instead of embedding credentials, assign permissions to services using **IAM Roles**.

```
┌──────────────┐         Assigned         ┌──────────────┐         Requests Access         ┌───────────────┐
│ EC2 Instance │  ═════════════════════>  │   IAM Role   │  ═════════════════════════════> │ AWS Service   │
│ / Lambda     │   (Temporary Credentials)│              │                                 │ (e.g., S3)    │
└──────────────┘                          └──────────────┘                                 └───────────────┘
```

- **EC2 Instance Profile**: Enables an EC2 instance to perform API requests automatically without storing key files.
- **Lambda Function Roles**: Grants Lambda functions execution permissions to access other services.

### AWS CLI & SDK Credentials Resolution Order

When running AWS CLI or SDK commands, AWS resolves credentials in a specific precedence order:

1. **Command Line Options**: `-region`, `-profile`, etc.
2. **Environment Variables**:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
    - `AWS_SESSION_TOKEN` (for temporary credentials)
    - `AWS_DEFAULT_REGION`
3. **CLI Credentials File**: `~/.aws/credentials`
4. **CLI Configuration File**: `~/.aws/config`
5. **Container Credentials**: Used in Amazon ECS / EKS tasks.
6. **Instance Profile Credentials**: Retrieved from the EC2 Instance Metadata Service (IMDS).

### AWS CLI Commands Quick Sheet

### Configuration & Verification

Bash

```
# Configure default profile
aws configure

# List IAM users 
aws iam list-users

# Configure named profile
aws configure --profile my-profile

# Verify active user / identity
aws sts get-caller-identity
```

### S3 Operations via CLI

Bash

```
# Copy local file to S3 bucket
aws s3 cp myfile.txt s3://mybucket/myfile.txt

# List contents of a bucket
aws s3 ls s3://mybucket
```

### Important Best Practices Summary

- **Never use Root** for regular administrative or developer tasks.
- **Assign permissions to Groups**, not individual users.
- **Use IAM Roles** for applications running on AWS services (EC2, Lambda) instead of static Access Keys.
- **Audit permissions periodically** using IAM Access Advisor and Credential Reports.
