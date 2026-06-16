#!/bin/bash

# Floci AWS Emulator Demo Script
# This script demonstrates basic Floci operations using AWS CLI

set -e

# Configuration
FLOCI_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"
AWS_ACCESS_KEY="test"
AWS_SECRET_KEY="test"

echo "=========================================="
echo "Floci AWS Emulator Demo"
echo "=========================================="
echo ""

# Check if Floci is running
echo "Checking if Floci is running on port 4566..."
if ! curl -s --head --max-time 2 "$FLOCI_ENDPOINT" > /dev/null; then
    echo "Floci is not running. Starting Floci..."
    docker run -d --name floci -p 4566:4566 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        floci/floci:latest
    echo "Waiting for Floci to start..."
    sleep 5
else
    echo "Floci is already running!"
fi

echo ""
echo "Setting up AWS CLI environment..."
export AWS_ENDPOINT_URL=$FLOCI_ENDPOINT
export AWS_DEFAULT_REGION=$AWS_REGION
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY

echo ""
echo "=========================================="
echo "Demo 1: S3 Bucket Operations"
echo "=========================================="

# Create S3 bucket
BUCKET_NAME="my-test-bucket-$(date +%s)"
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME

# List buckets
echo ""
echo "Listing S3 buckets:"
aws s3 ls

# Create a test file
echo "Hello from Floci!" > /tmp/test-file.txt

# Upload file to S3
echo ""
echo "Uploading test file to S3..."
aws s3 cp /tmp/test-file.txt s3://$BUCKET_NAME/

# List objects in bucket
echo ""
echo "Listing objects in bucket:"
aws s3 ls s3://$BUCKET_NAME/

echo ""
echo "=========================================="
echo "Demo 2: SQS Queue Operations"
echo "=========================================="

# Create SQS queue
QUEUE_NAME="my-test-queue"
echo "Creating SQS queue: $QUEUE_NAME"
QUEUE_URL=$(aws sqs create-queue --queue-name $QUEUE_NAME --query 'QueueUrl' --output text)
echo "Queue URL: $QUEUE_URL"

# Send message to queue
echo ""
echo "Sending message to SQS queue..."
aws sqs send-message --queue-url $QUEUE_URL --message-body "Hello from Floci SQS!"

# Receive message from queue
echo ""
echo "Receiving message from SQS queue..."
aws sqs receive-message --queue-url $QUEUE_URL

echo ""
echo "=========================================="
echo "Demo 3: DynamoDB Operations"
echo "=========================================="

# Create DynamoDB table
TABLE_NAME="my-test-table"
echo "Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# Put item
echo ""
echo "Adding item to DynamoDB table..."
aws dynamodb put-item \
    --table-name $TABLE_NAME \
    --item '{"id":{"S":"item1"},"name":{"S":"Test Item"},"value":{"N":"42"}}'

# Get item
echo ""
echo "Getting item from DynamoDB table..."
aws dynamodb get-item \
    --table-name $TABLE_NAME \
    --key '{"id":{"S":"item1"}}'

echo ""
echo "=========================================="
echo "Cleanup"
echo "=========================================="

# Clean up - delete resources
echo "Deleting test file..."
rm -f /tmp/test-file.txt

echo "Deleting SQS queue..."
aws sqs delete-queue --queue-url $QUEUE_URL

echo "Deleting DynamoDB table..."
aws dynamodb delete-table --table-name $TABLE_NAME

echo "Deleting S3 bucket..."
aws s3 rb s3://$BUCKET_NAME --force

echo ""
echo "=========================================="
echo "Demo completed successfully!"
echo "=========================================="
