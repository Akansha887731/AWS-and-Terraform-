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
<img width="1052" height="587" alt="image" src="https://github.com/user-attachments/assets/28c09c26-1b9a-4a03-afba-e3b761560239" />


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
## 5. Amazon Data Firehose (formerly Kinesis Data Firehose)

Amazon Data Firehose is a fully managed, serverless stream-loading service used to load real-time streaming data into data stores and analytics tools.

### 🔹 Key Characteristics & Capabilities

- **Near Real-Time**: Buffers incoming streaming data by **Buffer Size** (1 MB to 128 MB) or **Buffer Interval** (60 to 900 seconds) before flushing.
- **Serverless & Auto-Scaling**: Automatically scales throughput; no shard management or provisioning required.
- **Destinations**:
    - **AWS**: Amazon S3, Amazon Redshift (via S3 COPY command), Amazon OpenSearch Service.
    - **3rd-Party**: Datadog, Splunk, NewRelic, MongoDB.
    - **Custom**: Any HTTP Endpoint.
- **Transformations & Format Conversions**:
    - Uses **AWS Lambda** for inline data transformations (e.g., JSON modification, CSV-to-JSON).
    - Natively converts JSON records into columnar formats like **Apache Parquet** or **Apache ORC** for efficient querying in Athena.
    - Compresses payloads (GZIP, ZIP, Snappy) before saving to destinations.
- **No Persistence / No Replay**: Firehose does not persist records; data **cannot be replayed**. (Can configured to backup failed/all source records to an S3 bucket).

## 6. Amazon Kinesis Data Streams Operations & Scaling

- **Kinesis Client Library (KCL)**: A Java library (with wrappers for Python/Node) that simplifies building consumers.
    - Uses **Amazon DynamoDB** to maintain lease checkpoints and track shard consumption progress.
    - Rule: The number of KCL consumer instances/threads **should not exceed the number of shards** in the stream.
- **Shard Splitting & Merging**:
    - **Splitting**: Divides a high-traffic shard into two shards to increase capacity (handles hot keys).
    - **Merging**: Combines two low-traffic shards into one shard to lower costs (handles cold keys).
- **Kinesis Producer Library (KPL)**: High-performance C++/Java library that improves throughput via **Batching** (aggregating multiple records into a single payload).

## 7. Amazon MQ (Managed Message Broker)

- **Purpose**: Managed message broker for open-source messaging protocols: **Apache ActiveMQ** and **RabbitMQ**.
- **Primary Use Case**: Migrating legacy, on-premises applications that rely on industry-standard APIs (JMS, AMQP, MQTT, STOMP, OpenWire) to AWS without rewriting code to use native SQS/SNS APIs.
- **Deployment Models**: Supports single-broker deployments or high-availability active/standby deployments across Multi-AZs.

## 8. AWS Step Functions (Workflow Orchestration)

- **Purpose**: Serverless visual workflow orchestrator that coordinates distributed applications and AWS services using **State Machines** defined in Amazon States Language (ASL / JSON).
- **Workflow Types**:
    - **Standard Workflows**: Long-running (up to 1 year), durable, audit-tracked workflows; ideal for core business processes.
    - **Express Workflows**: High-volume, short-duration (up to 5 minutes) event processing tasks.
- **Key Features**: Built-in error handling, automatic retries (`Retry`), catch blocks (`Catch`), sequence branching, parallel processing (`Parallel`), and manual human approval tasks.

## 9. Additional Advanced SQS & SNS Concepts

- **SQS Message Deduplication (FIFO)**:
    - **Explicit**: Provide a `MessageDeduplicationId` in the `SendMessage` call.
    - **Content-Based Deduplication**: SQS computes an SHA-256 hash of the `MessageBody` to auto-generate the deduplication ID.
- **SQS Kinesis/S3 Event Integration**: Resource access policies on SQS must grant `sqs:SendMessage` permissions to the event source service principal (e.g., `s3.amazonaws.com` or `sns.amazonaws.com`).
- **SNS Dead Letter Queues**: Subscriptions can have an associated SQS DLQ to catch undelivered push notifications if client endpoints or HTTP endpoints are down.

## 10. Master Service Comparison Table

| Service | Primary Architecture | Retention | Latency | Replay Ability? |
| --- | --- | --- | --- | --- |
| **Amazon SQS** | Pull / Queueing | 1 min – 14 days | Real-Time | No (Deleted on process) |
| **Amazon SNS** | Push / Pub-Sub | Ephemeral (0s) | Real-Time | No (Sent immediately) |
| **Kinesis Data Streams** | Streaming / Shards | 24 hrs – 365 days | Real-Time (~200ms) | **Yes** (Replay shards) |
| **Amazon Data Firehose** | Near Real-time Ingestion | None (Pass-through) | Near Real-time (60s+) | No |
| **Amazon MQ** | Legacy Broker (ActiveMQ/RabbitMQ) | Memory / Disk queue | Real-Time | No |
| **AWS Step Functions** | Workflow State Machine | Up to 1 year (Standard) | Dynamic | State Retries / Execution |

# Important diagrams:

### 1. The SNS + SQS Fanout Pattern

*(Use Case: Pub/Sub Decoupling, Event Broadcasting, & Message Filtering)*

This pattern is essential because it demonstrates how to handle **one-to-many communication** while protecting individual downstream microservices with dedicated queues.

<img width="890" height="587" alt="image" src="https://github.com/user-attachments/assets/8f4d92ba-5877-46cc-ba52-7afca6530ea9" />

- **Why it matters:**
    1. **Publisher Isolation:** The application sends events **once** to SNS and doesn't care who processes them.
    2. **Asynchronous Retries & Dead-Lettering:** If `Worker 2` crashes, messages pile up safely in `SQS Queue 2` without affecting `Queue 1` or `Queue 3`.
    3. **Attribute Filtering:** `SQS Queue 2` and `3` only get subset messages matching their **Subscription Filter Policies**, eliminating extra filtering code in workers.

### 2. Stream Processing vs. Direct Storage Load (KDS vs. Firehose)

*(Use Case: Choosing between Real-Time Analytics and Near-Real-Time Ingestion)*

This side-by-side comparison shows when to route streaming data through **Kinesis Data Streams (KDS)** versus **Amazon Data Firehose**.

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 DATA PRODUCERS                                          │
│                   (Application Logs, IoT Sensors, Clickstream Data)                     │
└──────────────────────────────┬──────────────────────────┬───────────────────────────────┘
                               │                          │
                               │ Custom Stream            │ Direct Ingestion
                               ▼                          ▼
┌───────────────────────────────────────────────┐  ┌──────────────────────────────────────┐
│             KINESIS DATA STREAMS              │  │         AMAZON DATA FIREHOSE         │
│  • Low Latency (~200ms)                       │  │  • Near Real-time (60s–900s buffer)  │
│  • Storage: 1 to 365 Days                     │  │  • No Storage / No Replay            │
│  • Supports Historical Replay                 │  │  • Auto-scales (No shards)           │
│  • Provisioned / On-Demand Shards             │  │  • Optional Inline Lambda Transform  │
└──────────────────────┬────────────────────────┘  └──────────────────┬───────────────────┘
                       │                                              │
┌─────────────┴─────────────┐                                        │ Converts to
▼                           ▼                                        │ Parquet/ORC
┌─────────────────┐         ┌─────────────────┐                       ▼
│ Custom App      │         │ AWS Lambda      │             ┌───────────────────┐
│ (KCL Consumer   │         │ (Event Source   │             │ Storage & Search  │
│ via DynamoDB)   │         │  Mapping)       │             │ Destinations      │
└────────┬────────┘         └────────┬────────┘             │ • Amazon S3       │
         │                           │                      │ • Redshift        │
         ▼                           ▼                      │ • OpenSearch      │
┌─────────────────┐         ┌─────────────────┐             │ • Datadog/Splunk  │
│ Real-Time Fraud │         │ Real-Time       │             └───────────────────┘
│ Analytics Engine│         │ Dashboard       │
└─────────────────┘         └─────────────────┘
```

- **Why it matters:**
    - **Kinesis Data Streams (Left side):** Used when **multiple custom consumers** need real-time data, complex event ordering, or the ability to re-process/replay data later.
    - **Amazon Data Firehose (Right side):** Used when you simply want to **load data into a database, search index, or data lake** with zero operational overhead and built-in format conversion (e.g., Parquet).
      
