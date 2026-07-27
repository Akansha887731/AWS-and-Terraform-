# EC2 instance storage

# 📌 Amazon EC2 – Instance Storage Notes

## 1. Amazon EBS (Elastic Block Store)

Amazon EBS is a network drive that you attach to your EC2 instances while they run. It allows instances to persist data even after termination.

### Key Characteristics:

- **Network Drive**: It is a virtual hard drive that communicates with EC2 over the network (which means there can be slight latency).
- **AZ Locked**: An EBS volume is created in a **specific Availability Zone (AZ)**. To move a volume across AZs, you must take a snapshot and restore it in the target AZ.
- **Flexible Attachment**: Can be detached from an EC2 instance and attached to another in the same AZ.

### EBS Attributes & Features:

- **Delete on Termination Attribute**:
    - **Root Volume**: Deleted by default when the EC2 instance is terminated.
    - **Attached Volumes**: NOT deleted by default upon instance termination.
    - Can be modified via the AWS Console or AWS CLI.
- **EBS Snapshots**:
    - An **incremental backup** of your EBS volume stored in Amazon S3.
    - **Moving AZs/Regions**: Snapshots can be copied across Regions or used to recreate volumes in a different AZ.
    - **EBS Snapshot Archive**: Moves snapshots to an archive tier that is up to 75% cheaper; takes 24 to 72 hours to restore.
    - **Recycle Bin for EBS Snapshots**: Protects against accidental deletion (retention period from 1 day to 1 year).
    - **Fast Snapshot Restore (FSR)**: Forces full initialization of the snapshot to eliminate latency on first-access reads.
- **EBS Encryption**:
    - Encrypts data at rest inside the volume, data in transit between instance and volume, all snapshots, and volumes created from those snapshots.
    - Handled transparently using **AWS KMS** keys.

## 2. EBS Volume Types

AWS offers 4 main categories of EBS storage volumes:

| **Volume Type** | **Abbreviation** | **Use Cases** | **Max IOPS / Throughput** |
| --- | --- | --- | --- |
| **General Purpose SSD** | `gp2` / `gp3` | System boot volumes, virtual desktops, development & testing environments. | • `gp3`: 16,000 IOPS, 1,000 MB/s   • `gp2`: 16,000 IOPS (IOPS scales with size)  |
| **Provisioned IOPS SSD** | `io1` / `io2` | Critical line-of-business applications, high-performance databases requiring > 16,000 IOPS. | • `io1`: 64,000 IOPS (Nitro)   • `io2 Block Express`: 256,000 IOPS, sub-millisecond latency  |
| **Throughput Optimized HDD** | `st1` | Big data, data warehouses, log processing (frequent, throughput-intensive). | 500 MB/s throughput (Cannot be boot volume)  |
| **Cold HDD** | `sc1` | Unfrequently accessed data, lowest cost storage for large data sets. | 250 MB/s throughput (Cannot be boot volume)  |

> 
> 
> 
> **💡 Exam Note on EBS Multi-Attach (`io1` / `io2`)**: Allows attaching a single `io1` or `io2` volume to **multiple EC2 instances** (up to 16) in the same AZ. Requires a cluster-aware file system (e.g., GFS2).


## 3. EC2 Instance Store

If you need **extreme I/O performance** and low-latency disk storage, network-attached EBS volumes might present a bottleneck. You can instead use **EC2 Instance Store**.

### Key Characteristics:

- **Hardware-Attached**: Physical block storage disks directly attached to the host server running your EC2 instance.
- **High Performance**: Extremely high IOPS and low latency.
- **Ephemeral (Temporary)**:
    - If the EC2 instance is **stopped or terminated**, data on the Instance Store is **LOST**.
    - Data survives host reboots.
- **Use Cases**: Temporary storage, scratch pads, buffers, caches, in-memory processing.
- **User Responsibility**: You must back up/replicate data manually to EBS or S3 if resilience is required.

## 4. Amazon Machine Image (AMI)

An **AMI** is a customized package containing an OS, pre-installed software, configuration files, and monitoring agents used to launch EC2 instances.

- **Benefits**: Faster boot times because software is pre-packaged.
- **Scope**: AMIs are built for a **specific Region** (can be copied across Regions).
- **Sources**:
    - **Public AMI**: Default AWS-provided images (e.g., Amazon Linux 2, Ubuntu).
    - **Your Own AMI**: Custom-created and maintained by you.
    - **AWS Marketplace AMI**: Pre-built software solutions created by third parties.

### 🔄 Process: Creating an AMI from an Instance

```
┌─────────────────┐       Stop Instance       ┌───────────────────┐       Create AMI       ┌───────────────────┐
│ EC2 Instance    │ ────────────────────────> │ EC2 Instance      │ ─────────────────────> │ Custom AMI +      │
│ (Customized OS) │   (For Data Integrity)    │ (Stopped State)   │                        │ EBS Snapshot      │
└─────────────────┘                           └───────────────────┘                        └───────────────────┘
                                                                                                     │
                                                                                                     ▼
                                                                                           Launch instances in
                                                                                            US-EAST-1A / 1B
```

## 5. Amazon EFS (Elastic File System)

Amazon EFS is a managed **Network File System (NFS)** that can be mounted simultaneously onto hundreds of EC2 instances across multiple Availability Zones.

### Key Characteristics:

- **Multi-AZ Access**: Works across multiple AZs within a VPC.
- **Compatibility**: Compatible with **Linux-based AMIs only** (not Windows). Uses `NFSv4.1` protocol.
- **Security & Access**: Uses **Security Groups** attached to EFS Mount Targets to control access.
- **Storage Classes**:
    - **EFS Standard**: For frequently accessed data.
    - **EFS Infrequent Access (EFS-IA)**: Cost-optimized tier for infrequently accessed files (retrieval fee applies).
    - **EFS Archive**: For rarely accessed data (accessed a few times a year), 50% cheaper than IA.
    - **Lifecycle Management**: Automatically shifts files to lower tiers based on access patterns.

## 6. Summary Comparison: EBS vs. Instance Store vs. EFS

| **Feature** | **Amazon EBS** | **EC2 Instance Store** | **Amazon EFS** |
| --- | --- | --- | --- |
| **Type** | Network Block Storage  | Physical Local Hardware  | Network File System (NFS)  |
| **Scope / Availability** | Single Availability Zone (AZ)  | Single Host Server  | Multi-AZ (Regional)  |
| **Persistence** | Persists after instance stop/termination  | Ephemeral (Lost on instance stop/terminate)  | Persists independently  |
| **Performance** | High performance (up to 256k IOPS)  | Highest I/O performance  | Scalable file storage  |
| **OS Support** | Linux / Windows / Mac  | Linux / Windows / Mac | Linux-based only  |
| **Concurrent Connections** | 1 instance (up to 16 with Multi-Attach `io1`/`io2`)  | 1 instance  | 100s of instances simultaneously  |

