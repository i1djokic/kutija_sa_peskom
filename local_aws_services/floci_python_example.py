#!/usr/bin/env python3
"""
Floci AWS Emulator Python Example
Demonstrates using boto3 with Floci local AWS emulator
"""

import boto3
import json
import time

# Floci configuration
FLOCI_ENDPOINT = "http://localhost:4566"
AWS_REGION = "us-east-1"
AWS_ACCESS_KEY = "test"
AWS_SECRET_KEY = "test"

def create_aws_client(service):
    """Create boto3 client configured for Floci"""
    return boto3.client(
        service,
        endpoint_url=FLOCI_ENDPOINT,
        region_name=AWS_REGION,
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY
    )

def demo_s3_operations():
    """Demonstrate S3 operations with Floci"""
    print("\n" + "="*50)
    print("S3 Operations Demo")
    print("="*50)

    s3 = create_aws_client('s3')
    bucket_name = f"python-test-bucket-{int(time.time())}"

    # Create bucket
    print(f"Creating bucket: {bucket_name}")
    s3.create_bucket(Bucket=bucket_name)

    # List buckets
    print("\nListing buckets:")
    response = s3.list_buckets()
    for bucket in response['Buckets']:
        print(f"  - {bucket['Name']}")

    # Upload object
    print(f"\nUploading test object to {bucket_name}")
    s3.put_object(
        Bucket=bucket_name,
        Key="hello.txt",
        Body=b"Hello from Python + Floci!"
    )

    # Get object
    print("\nRetrieving object:")
    response = s3.get_object(Bucket=bucket_name, Key="hello.txt")
    print(f"Content: {response['Body'].read().decode('utf-8')}")

    # List objects
    print("\nListing objects in bucket:")
    response = s3.list_objects_v2(Bucket=bucket_name)
    for obj in response.get('Contents', []):
        print(f"  - {obj['Key']} ({obj['Size']} bytes)")

    # Cleanup
    print(f"\nCleaning up: deleting bucket {bucket_name}")
    s3.delete_object(Bucket=bucket_name, Key="hello.txt")
    s3.delete_bucket(Bucket=bucket_name)

def demo_sqs_operations():
    """Demonstrate SQS operations with Floci"""
    print("\n" + "="*50)
    print("SQS Operations Demo")
    print("="*50)

    sqs = create_aws_client('sqs')
    queue_name = "python-test-queue"

    # Create queue
    print(f"Creating queue: {queue_name}")
    response = sqs.create_queue(QueueName=queue_name)
    queue_url = response['QueueUrl']
    print(f"Queue URL: {queue_url}")

    # Send message
    print("\nSending message to queue...")
    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody="Hello from Python SQS!"
    )

    # Receive message
    print("\nReceiving message from queue...")
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1
    )

    if 'Messages' in response:
        for msg in response['Messages']:
            print(f"Message: {msg['Body']}")
            # Delete message after receiving
            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=msg['ReceiptHandle']
            )

    # Cleanup
    print(f"\nCleaning up: deleting queue")
    sqs.delete_queue(QueueUrl=queue_url)

def demo_dynamodb_operations():
    """Demonstrate DynamoDB operations with Floci"""
    print("\n" + "="*50)
    print("DynamoDB Operations Demo")
    print("="*50)

    dynamodb = create_aws_client('dynamodb')
    table_name = "python-test-table"

    # Create table
    print(f"Creating table: {table_name}")
    dynamodb.create_table(
        TableName=table_name,
        KeySchema=[
            {'AttributeName': 'id', 'KeyType': 'HASH'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'id', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )

    # Wait for table to be active
    print("Waiting for table to become active...")
    waiter = dynamodb.get_waiter('table_exists')
    waiter.wait(TableName=table_name)

    # Put item
    print("\nAdding item to table...")
    dynamodb.put_item(
        TableName=table_name,
        Item={
            'id': {'S': 'item1'},
            'name': {'S': 'Python Test Item'},
            'count': {'N': '100'}
        }
    )

    # Get item
    print("\nGetting item from table...")
    response = dynamodb.get_item(
        TableName=table_name,
        Key={'id': {'S': 'item1'}}
    )
    if 'Item' in response:
        item = response['Item']
        print(f"Retrieved: id={item['id']['S']}, name={item['name']['S']}, count={item['count']['N']}")

    # Cleanup
    print(f"\nCleaning up: deleting table {table_name}")
    dynamodb.delete_table(TableName=table_name)

def main():
    print("Floci AWS Emulator - Python Example")
    print("Make sure Floci is running on http://localhost:4566")

    try:
        demo_s3_operations()
        demo_sqs_operations()
        demo_dynamodb_operations()

        print("\n" + "="*50)
        print("All demos completed successfully!")
        print("="*50)
    except Exception as e:
        print(f"\nError: {e}")
        print("Make sure Floci is running: docker run -p 4566:4566 floci/floci:latest")

if __name__ == "__main__":
    main()
