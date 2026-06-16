#!/bin/bash
# Deploy CloudFormation stack to AWS

set -e

STACK_NAME="api-gateway-lambda-demo"
TEMPLATE_FILE="template.yaml"
ENVIRONMENT="dev"

echo "=========================================="
echo "Deploying to AWS"
echo "Stack: $STACK_NAME"
echo "Template: $TEMPLATE_FILE"
echo "=========================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI not configured. Run 'aws configure' first."
    exit 1
fi

# Package Lambda code (if using S3 for larger deployments)
echo ""
echo "Deploying CloudFormation stack..."

aws cloudformation deploy \
    --stack-name $STACK_NAME \
    --template-file $TEMPLATE_FILE \
    --parameter-overrides EnvironmentName=$ENVIRONMENT \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset

# Get stack outputs
echo ""
echo "=========================================="
echo "Stack Outputs"
echo "=========================================="

API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" \
    --output text)

echo "API Endpoint: $API_ENDPOINT"
echo ""
echo "Testing the API..."
curl -s "$API_ENDPOINT" | json_pp || curl -s "$API_ENDPOINT"

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="
echo ""
echo "To update the Lambda function code:"
echo "  aws lambda update-function-code --function-name hello-world-$ENVIRONMENT --zip-file fileb://lambda.zip"
echo ""
echo "To delete the stack:"
echo "  aws cloudformation delete-stack --stack-name $STACK_NAME"
echo ""
