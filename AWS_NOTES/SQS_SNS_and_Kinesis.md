# 📌 Messaging & Streaming Services: SQS, SNS & Kinesis

## 1. Amazon SQS (Simple Queue Service)

Amazon SQS is a fully managed **decoupling/message queuing service** that uses a **pull-based (polling) model** where consumers pull messages from the queue.

### 🔹 Queue Types

- **Standard Queue**:
    - Unlimited throughput.
    - **At-least-once delivery** (messages can occasionally be delivered more than once).
    - **Best-effort ordering** (messages may arrive out of sequence).
- **FIFO (First-In-First-Out) Queue**:
    - Guarantees **exactly-once processing** and **strict ordering**.
    - Throughput: 300 msg/sec (up to 3,000 msg/sec with batching).
    - Requires a `.fifo` suffix in the queue name.
    - Uses **Message Group ID** to group messages for ordered processing and **Message Deduplication ID** (or Content-Based Deduplication) within a 5-minute deduplication interval.

### 🔹 Key Operational Timers & Parameters

| **Configuration / Term** | **Default** | **Range / Limit** | **Exam Significance** |
| --- | --- | --- | --- |
| **Message Size** | — | **256 KB** max | Use **Amazon S3 Java Client SDK** (Extended Client) to offload payloads larger than 256 KB up to 2 GB. |
| **Message Retention** | 4 days | **1 minute to 14 days** | If a message is not processed within the retention window, SQS automatically deletes it. |
| **Visibility Timeout** | 30 seconds | **0 seconds to 12 hours** | When a consumer polls a message, it becomes invisible to other consumers. If not deleted before timeout expires, it becomes visible again. Modify dynamically using `ChangeMessageVisibility`. |
| **Delivery Delay** | 0 seconds | **0 seconds to 15 minutes** | Delays message visibility to consumers upon initial enqueueing. |
| **Long Polling** | Short (0s) | **1 second to 20 seconds** | Set `WaitTimeSeconds > 0` to reduce API costs and empty responses by letting SQS wait until messages arrive. |

### 🔹 DLQ (Dead Letter Queue) & Request-Response Pattern

- **Dead Letter Queue (DLQ)**:
    - Receives messages that fail processing after a specified threshold (`maxReceiveCount`).
    - Useful for debugging poison-pill messages.
    - Must be of the **same queue type** (Standard DLQ for Standard Queue; FIFO DLQ for FIFO Queue).
- **SQS Temporary Queue Client**:
    - Implements request-response virtual queues on a single SQS queue without creating multiple physical queues.

### 🔹 Security & Access Policy

- **Encryption**:
    - In-Flight: HTTPS API endpoints.
    - At-Rest: AWS KMS keys.
    - Client-Side: Encryption/decryption handled by the application code.
- **Access Control**:
    - **IAM Policies**: Regulates API actions for principal roles/users.
    - **SQS Access Policies**: Resource-based policies (similar to S3 bucket policies) to allow cross-account access or permit services like SNS and S3 to write to the queue.

## 2. Amazon SNS (Simple Notification Service)

Amazon SNS is a fully managed **publish/subscribe (pub/sub) messaging service** using a **push-based model**.

### 🔹 Core Features

- **Publisher / Subscriber Architecture**:
    - Publishers send messages to an **SNS Topic**.
    - Subscribers (SQS queues, Lambda functions, HTTP/S endpoints, Email, SMS, Mobile Push) receive copies instantly.
- **Topic Types**:
    - **Standard Topic**: Unlimited throughput, best-effort ordering.
    - **FIFO Topic**: Guarantees strict ordering and deduplication; can only have **SQS FIFO queues as subscribers**.

### 🔹 Key SNS Capabilities

1. **SNS Fanout Pattern**:
    - Publishing a single message to an SNS topic that fans out to multiple SQS queues running separate processing pipelines (e.g., Payment Processing, Analytics, Fraud Detection).
2. **Message Filtering**:
    - Uses **Subscription Filter Policies** (JSON format) so subscribers receive *only* messages containing specific attributes instead of filtering in code.
3. **Security**:
    - In-flight HTTPS, KMS at-rest encryption, IAM policies, and **SNS Topic Access Policies** to allow external services (e.g., S3 Event Notifications) to publish to the topic.

## 3. Amazon Kinesis (Data Streams & Data Firehose)

Amazon Kinesis is designed for ingesting, processing, and streaming **real-time big data**.

### 🔹 Kinesis Data Streams (KDS)

- **Architecture**: Composed of individual **Shards** that provide dedicated compute/throughput.
    - **1 Shard** = 1 MB/sec (or 1,000 records/sec) Ingestion | 2 MB/sec Egress.
- **Capacity Modes**:
    - **Provisioned**: You manually manage shard counts.
    - **On-Demand**: Auto-scales shards based on throughput.
- **Partition Key**: Determines which shard receives the record (hashed to a shard ID).
- **Data Retention**: 24 hours by default (configurable up to 365 days).
- **Consumers**:
    - **Shared (Classic) Fan-out Consumer**: 2 MB/sec shared per shard among all consumers (pull via `GetRecords`).
    - **Enhanced Fan-out Consumer**: 2 MB/sec *per consumer per shard* (push via HTTP/2).

### Stimulation & Comparison: SQS vs. SNS vs. Kinesis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            MESSAGING PATTERNS                               │
├──────────────────────────┬──────────────────────┬───────────────────────────┤
│    Amazon SQS (Pull)     │   Amazon SNS (Push)  │ Amazon Kinesis (Streaming)│
│                          │                      │                           │
│  ┌──────┐    ┌────────┐  │  ┌──────┐  ┌───────┐ │ ┌──────────┐  ┌─────────┐ │
│  │ Prod │──> │ Queue  │  │  │ Prod │─>│ Topic │ │ │Producers │─>│ Kinesis │ │
│  └──────┘    └───┬────┘  │  └──────┘  └───┬───┘ │ └──────────┘  │ Stream  │ │
│                  │       │          ┌─────┴──┐  │               └────┬────┘ │
│                Polling   │          ▼        ▼  │                    │      │
│                  ▼       │      ┌──────┐  ┌───┐ │                Shards     │
│             ┌────────┐   │      │ SQS  │  │λ  │ │                    ▼      │
│             │Consumer│   │      └──────┘  └───┘ │               ┌─────────┐ │
│             └────────┘   │                      │               │Consumers│ │
└──────────────────────────┴──────────────────────┴───────────────┴─────────┘_|
```

| **Dimension** | **Amazon SQS** | **Amazon SNS** | **Amazon Kinesis Data Streams** |
| --- | --- | --- | --- |
| **Model** | Pull-based (Polling) | Push-based (Pub/Sub) | Pull/Push Streaming |
| **Data Persistence** | Deleted once consumed or expired | Ephemeral (not stored; sent immediately) | Retained for 1–365 days |
| **Consumers** | 1 consumer group per queue | Multiple subscribers per topic | Multiple applications replay/read in parallel |
| **Ordering** | Guaranteed only in FIFO | Guaranteed only in FIFO | Guaranteed per Shard (via Partition Key) |
| **Primary Use Case** | Application decoupling & job buffering | Mass notification & event fanout | Real-time big data analytics & streaming |

## 4. Code Implementation Examples

### 💻 1. Send Message with Long Polling in SQS (Python / boto3)

```
import boto3

sqs = boto3.client('sqs')
queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/my-queue'

# 1. Send Message
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Processing order #1001',
    DelaySeconds=0
)

# 2. Receive Message using Long Polling (WaitTimeSeconds = 20)
response = sqs.receive_message(
    QueueUrl=queue_url,
    AttributeNames=['All'],
    MaxNumberOfMessages=10,
    WaitTimeSeconds=20  # Enables Long Polling to lower costs
)
```

### 💻 2. Publish to SNS with Message Attributes (for Filtering)

```
import boto3

sns = boto3.client('sns')

sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123456789012:OrderEvents',
    Message='Order successfully placed!',
    Subject='New Order',
    MessageAttributes={
        'store': {
            'DataType': 'String',
            'StringValue': 'online_store'
        },
        'event_type': {
            'DataType': 'String',
            'StringValue': 'order_placed'
        }
    }
)
```

### 💻 3. Put Record into Kinesis Stream

```
import boto3
import json

kinesis = boto3.client('kinesis')

payload = {'sensor_id': 'sensor_42', 'temperature': 98.6}

kinesis.put_record(
    StreamName='SensorDataStream',
    Data=json.dumps(payload),
    PartitionKey='sensor_42'  # Ensures same sensor data goes to same shard
)
```
