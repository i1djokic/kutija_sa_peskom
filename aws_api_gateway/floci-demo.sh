#!/bin/bash
# Local testing with floci - AWS API Gateway + Lambda demo

set -e

# Configuration
FLOCI_ENDPOINT="http://localhost:4566"
AWS_REGION="us-east-1"
AWS_ACCESS_KEY="test"
AWS_SECRET_KEY="test"
STACK_NAME="api-gateway-lambda-local"

echo "=========================================="
echo "AWS API Gateway + Lambda - Local Demo"
echo "Using floci AWS emulator"
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
    sleep 10
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
echo "Deploying CloudFormation Stack Locally"
echo "=========================================="

# Deploy the CloudFormation stack
aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file template.yaml \
    --parameter-overrides EnvironmentName=local \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset

echo ""
echo "=========================================="
echo "Stack Outputs"
echo "=========================================="

# Get stack outputs
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query "Stacks[0].Outputs" \
    --output table

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text)

echo ""
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Test the API
echo "=========================================="
echo "Testing the API"
echo "=========================================="

echo ""
echo "Test 1: Basic GET request"
curl -s "$API_ENDPOINT" | python3 -m json.tool || curl -s "$API_ENDPOINT"

echo ""
echo ""
echo "Test 2: GET request with query parameter"
curl -s "${API_ENDPOINT}?name=LocalTester" | python3 -m json.tool || curl -s "${API_ENDPOINT}?name=LocalTester"

echo ""
echo ""
echo "=========================================="
echo "Demo completed successfully!"
echo "=========================================="
echo ""
echo "To test manually:"
echo "  curl $API_ENDPOINT"
echo ""
echo "To view logs:"
echo "  aws logs describe-log-groups"
echo ""
echo "To delete the stack:"
echo "  aws cloudformation delete-stack --stack-name $STACK_NAME"
echo ""
