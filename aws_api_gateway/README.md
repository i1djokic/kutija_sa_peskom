# AWS API Gateway & Lambda Example

Simple project demonstrating Amazon API Gateway integration with AWS Lambda using CloudFormation, with local testing via floci.

Uses:
- **floci** - Local AWS services emulator for testing
- **AWS CLI** - AWS command-line interface
- **AWS CloudFormation** - Infrastructure as code
- **AWS Lambda** - Serverless compute
- **Amazon API Gateway** - RESTful API management

**Cost**: Local testing is free; AWS deployment is free tier eligible.

## Prerequisites

- Linux with Docker (for local testing with floci)
- Internet connection
- AWS account (for cloud deployment)

## Quick Setup

### Option 1: Automated Setup (Recommended)
```bash
chmod +x setup-linux.sh
./setup-linux.sh
```

### Option 2: Manual Setup
```bash
# Install Python3 and pip
sudo apt install -y python3 python3-pip   # Debian/Ubuntu
# or: sudo dnf install -y python3 python3-pip  # Fedora/RHEL

# Install dependencies
pip3 install awscli aws-sam-cli floci
```

## Local Testing (floci)
```bash
# Start local AWS emulator and deploy
./floci-demo.sh
```

## Deploying to AWS
```bash
# Configure AWS credentials
aws configure

# Deploy CloudFormation stack
./deploy.sh
```

## Testing the API
```bash
# Get API endpoint from stack output
aws cloudformation describe-stacks --stack-name api-gateway-lambda-demo --query "Stacks[0].Outputs[0].OutputValue" --output text

# Test endpoint
curl <endpoint-url>
```

## Learning Path
See [API_GATEWAY_LEARNING_GUIDE.md](./API_GATEWAY_LEARNING_GUIDE.md) for detailed instructions.

## Project Structure
```
aws_api_gateway/
├── README.md                    # This file
├── setup-linux.sh               # Dependency installer for Linux
├── template.yaml                # CloudFormation template
├── lambda_function.py           # Lambda function code
├── deploy.sh                    # AWS deployment script
├── floci-demo.sh                # Local testing script
└── API_GATEWAY_LEARNING_GUIDE.md  # Learning materials
```

## Resources
- **AWS API Gateway**: https://docs.aws.amazon.com/apigateway/
- **AWS Lambda**: https://docs.aws.amazon.com/lambda/
- **CloudFormation**: https://docs.aws.amazon.com/cloudformation/
- **floci**: https://github.com/flocus/floci
