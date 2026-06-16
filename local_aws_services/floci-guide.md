# Floci AWS Emulator - Quick Start Guide

## What is Floci?

Floci is a **fast, free, open-source AWS emulator** built with Quarkus Native. It's a drop-in replacement for LocalStack that starts in 24ms and uses only 13 MiB at idle.

### Key Features

| Feature | Description |
|---------|-------------|
| **No Auth Token** | Pull and run immediately - no sign-ups, no API keys, no telemetry |
| **138× Faster Startup** | Starts in 24ms vs ~3,300ms for LocalStack |
| **91% Less Memory** | 13 MiB idle footprint vs 143 MiB for LocalStack |
| **MIT Licensed** | Fork it, embed it, extend it - no restrictions |
| **41 AWS Services** | All services free and unlocked (S3, Lambda, DynamoDB, RDS, EKS, and more) |
| **Drop-in Replacement** | Same port 4566, same wire protocols, same AWS SDK calls |

### Performance Comparison

```
Startup Time:   Floci 24ms    vs  LocalStack 3,300ms  (138× faster)
Idle Memory:    Floci 13MiB   vs  LocalStack 143MiB   (91% less)
Docker Image:   Floci ~90MB   vs  LocalStack ~1.0GB
Lambda Through: Floci 289/s   vs  LocalStack 120/s    (2.4× faster)
```

## Getting Started

### Prerequisites
- Docker installed
- AWS CLI installed (for bash examples)
- Python 3 + boto3 (for Python examples)

### Start Floci

```bash
docker run --rm -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  floci/floci:latest
```

For services that use Docker (Lambda, ECS, RDS, ElastiCache), mount the Docker socket.

### Configure AWS CLI

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

## Supported AWS Services (41 total)

### Core Services
- **S3** - REST XML object storage
- **SQS** - FIFO + Standard queues
- **SNS** - Query/JSON notifications
- **DynamoDB** + Streams - JSON 1.1
- **Lambda** - Docker native (Node, Python, Java, Go, Ruby, .NET)

### Networking & Compute
- **API Gateway v1 + v2** ★
- **ECS** - Real Docker container tasks
- **EKS** - Real k3s clusters
- **EC2** - Real Docker containers with IMDS
- **ELB v2** ★ - ALB + NLB

### Data Services (Real Engines)
- **RDS** ★ - PostgreSQL, MySQL, MariaDB with IAM auth
- **ElastiCache** ★ - Redis with IAM auth (SigV4)
- **OpenSearch** - Real search clusters
- **MSK (Kafka)** - Apache Kafka via Redpanda

### Other Services
- **IAM** - 68+ operations
- **STS** - 7 operations
- **Cognito** ★ - JWKS
- **KMS** - Sign + Verify
- **Step Functions** - ASL support
- **CloudFormation** - Stacks
- **EventBridge** - Rules + Scheduler
- **Athena** - DuckDB-backed SQL queries
- **Glue** - Data Catalog
- **CodeBuild** ★ - Docker native builds
- **CodeDeploy** ★ - Lambda shifting
- **ECR** - OCI-compatible registry
- **Bedrock Runtime** ★ - Stub

★ = Exclusive to Floci (not in LocalStack Community)

## Bash Script (`floci-demo.sh`)

The included bash script demonstrates:

1. **Starting Floci** - Checks if running, starts if needed
2. **S3 Operations** - Create bucket, upload file, list objects
3. **SQS Operations** - Create queue, send/receive messages
4. **DynamoDB Operations** - Create table, put/get items
5. **Cleanup** - Remove all created resources

### Usage

```bash
# Make executable
chmod +x floci-demo.sh

# Run the demo
./floci-demo.sh
```

### Script Features
- Automatic Floci startup if not running
- Environment variable configuration
- Step-by-step AWS CLI examples
- Automatic cleanup of resources

## Python Example (`floci_python_example.py`)

The Python script shows how to use **boto3** with Floci:

1. **S3 Demo** - Bucket/object operations
2. **SQS Demo** - Queue message handling
3. **DynamoDB Demo** - Table/item operations

### Usage

```bash
# Install boto3 if needed
pip install boto3

# Run the example
python3 floci_python_example.py
```

### Python Code Features
- Reusable `create_aws_client()` function
- Clean error handling
- Waiters for async operations
- Automatic cleanup

## Real Engines vs Mocking

Floci uses **real engines** for complex services:

| Service | Engine Used |
|---------|-------------|
| Lambda | Real AWS runtimes in Docker |
| RDS | PostgreSQL, MySQL, MariaDB in Docker |
| ElastiCache | Real Redis container |
| ECS/EKS | Real Docker/k3s containers |
| Athena | DuckDB sidecar |
| MSK | Apache Kafka (Redpanda) |
| OpenSearch | Real OpenSearch clusters |

This guarantees **100% protocol fidelity** - no mocking, real wire protocols.

## IAM Integration

Floci supports **real IAM authentication** for:
- Lambda (role assumption)
- ElastiCache (SigV4 validation)
- RDS (JDBC IAM auth)
- ECS, EC2, MSK, EKS, OpenSearch, ECR, CodeBuild

## Azure Support

Floci also provides `floci-az` for local Azure emulation:

```bash
docker run --rm -p 4577:4577 \
  floci/floci-az:latest
```

Services: Blob, Queue, Table, Functions on port 4577.

## Resources

- **Website**: https://floci.io
- **GitHub (AWS)**: https://github.com/floci-io/floci
- **GitHub (Azure)**: https://github.com/floci-io/floci-az
- **Docs**: https://floci.io/floci/
- **License**: MIT

## Why Choose Floci?

| Feature | Floci | LocalStack Community |
|---------|-------|---------------------|
| Price | Free forever | Auth token required (since March 2026) |
| License | MIT | Restricted/BSL |
| Security updates | Active | Frozen (March 2026) |
| Startup time | ~24ms | ~3.3s |
| SDK compatibility | 100% (1,925/1,925 tests) | Partial |

---

**Light, fluffy, and always free.** Like *cirrocumulus floccus* - the cloud formation that gave Floci its name.
