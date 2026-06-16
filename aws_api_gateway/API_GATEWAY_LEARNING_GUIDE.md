# API Gateway & Lambda Learning Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Core Concepts](#core-concepts)
3. [Basic Commands](#basic-commands)
4. [Practice Exercises](#practice-exercises)
5. [Learning Path](#learning-path)
6. [Quick Reference](#quick-reference)

---

## Getting Started

### What You'll Learn
This project teaches you how to:
- Create AWS Lambda functions
- Set up Amazon API Gateway
- Integrate API Gateway with Lambda using CloudFormation
- Test locally using floci emulator

### Prerequisites
- AWS account (free tier eligible)
- AWS CLI installed and configured
- Basic understanding of REST APIs
- Python basics (for Lambda functions)

### Environment Setup

#### Option 1: Local Testing (Recommended for learning)
```bash
# Start floci (local AWS emulator)
docker run -d --name floci -p 4566:4566 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    floci/floci:latest

# Configure AWS CLI for local testing
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# Run the demo
./floci-demo.sh
```

#### Option 2: AWS Cloud Deployment
```bash
# Configure AWS credentials
aws configure

# Deploy to AWS
./deploy.sh
```

### Connecting to Local Environment
```bash
# Verify floci is running
curl http://localhost:4566

# List CloudFormation stacks
aws cloudformation list-stacks

# View Lambda functions
aws lambda list-functions
```

---

## Core Concepts

### Amazon API Gateway
API Gateway is a fully managed service that makes it easy to create, publish, maintain, and monitor RESTful APIs.

**Key Components:**
- **REST API** - The container for your API resources
- **Resource** - A path in your API (e.g., `/hello`)
- **Method** - HTTP verb (GET, POST, PUT, DELETE)
- **Integration** - Backend connection (Lambda, HTTP, Mock)
- **Stage** - Deployment environment (dev, prod)
- **Deployment** - Snapshot of API configuration

### AWS Lambda
Lambda is a serverless compute service that runs code in response to events.

**Key Concepts:**
- **Function** - Your code that runs in Lambda
- **Runtime** - Language environment (Python, Node.js, etc.)
- **Handler** - Entry point function
- **Event** - Input data to the function
- **Context** - Runtime information

### CloudFormation
Infrastructure as Code (IaC) service for defining AWS resources using YAML or JSON templates.

**Key Components:**
- **Resources** - AWS resources to create
- **Parameters** - Input values
- **Outputs** - Return values
- **Mappings** - Conditional values
- **Conditions** - Resource creation logic

### API Gateway + Lambda Integration Types
1. **AWS_PROXY** - Entire request forwarded to Lambda
2. **AWS** - Manual mapping of request/response
3. **HTTP** - Proxy to HTTP endpoint
4. **MOCK** - Return static response

---

## Basic Commands

### CloudFormation Commands
```bash
# Deploy stack
aws cloudformation deploy --stack-name my-stack --template-file template.yaml --capabilities CAPABILITY_IAM

# Describe stack
aws cloudformation describe-stacks --stack-name my-stack

# List stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Delete stack
aws cloudformation delete-stack --stack-name my-stack

# Validate template
aws cloudformation validate-template --template-body file://template.yaml
```

### Lambda Commands
```bash
# List functions
aws lambda list-functions

# Invoke function
aws lambda invoke --function-name my-function --payload '{}' response.json

# Update function code
aws lambda update-function-code --function-name my-function --zip-file fileb://lambda.zip

# Get function configuration
aws lambda get-function --function-name my-function

# View logs
aws logs describe-log-streams --log-group-name /aws/lambda/my-function
```

### API Gateway Commands
```bash
# List REST APIs
aws apigateway get-rest-apis

# Get API resources
aws apigateway get-resources --rest-api-id <api-id>

# Deploy API
aws apigateway create-deployment --rest-api-id <api-id> --stage-name dev

# Test API
curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/hello
```

### floci Local Testing Commands
```bash
# Start floci
docker run -p 4566:4566 floci/floci:latest

# Check status
curl http://localhost:4566

# Use with AWS CLI (set environment first)
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# All AWS CLI commands work the same locally
```

---

## Practice Exercises

### Beginner Level

#### Exercise 1: Deploy the Basic API
1. Start floci: `docker run -p 4566:4566 floci/floci:latest`
2. Configure AWS CLI for local endpoint
3. Run `./floci-demo.sh`
4. Test the API with curl
5. Check CloudFormation stack in floci

#### Exercise 2: Modify Lambda Response
1. Edit `lambda_function.py` to return a custom message
2. Update the function in CloudFormation or manually
3. Test the API again
4. Verify the new response

#### Exercise 3: Add Query Parameters
1. Pass a query parameter in the URL: `?name=YourName`
2. Modify Lambda to read `event['queryStringParameters']`
3. Return personalized greeting
4. Test with different names

### Intermediate Level

#### Exercise 4: Add POST Method
1. Add a new method in `template.yaml` for POST
2. Handle POST data in Lambda (`event['body']`)
3. Deploy and test with: `curl -X POST -d '{"name":"Test"}' <endpoint>`

#### Exercise 5: Add Another Resource
1. Create a new resource `/goodbye` in the template
2. Create a new Lambda function or reuse existing
3. Deploy and test both endpoints

#### Exercise 6: Add Error Handling
1. Add try/catch in Lambda
2. Return appropriate status codes (400, 500)
3. Test error scenarios

### Advanced Level

#### Exercise 7: Add Authentication
1. Add `AuthorizationType: COGNITO_USER_POOLS` or API Key
2. Create Cognito User Pool or API Key resource
3. Test with and without authentication

#### Exercise 8: Enable CORS
1. Add CORS headers in Lambda response
2. Add OPTIONS method for preflight requests
3. Test from a browser application

#### Exercise 9: Add CloudWatch Logging
1. Add IAM policy for CloudWatch Logs
2. Log request details in Lambda
3. View logs in CloudWatch (or local floci equivalent)

---

## Learning Path

### Week 1: Basics
- [ ] Day 1: Understand API Gateway concepts
- [ ] Day 2: Understand Lambda concepts
- [ ] Day 3: Deploy basic example locally with floci
- [ ] Day 4: Modify Lambda function code
- [ ] Day 5: Test different HTTP methods
- [ ] Day 6: Review CloudFormation template structure
- [ ] Day 7: Practice exercises 1-3

### Week 2: Intermediate
- [ ] Day 1: Add POST method support
- [ ] Day 2: Create multiple resources
- [ ] Day 3: Implement error handling
- [ ] Day 4: Add input validation
- [ ] Day 5: Deploy to real AWS
- [ ] Day 6: Monitor with CloudWatch
- [ ] Day 7: Practice exercises 4-6

### Week 3: Advanced
- [ ] Day 1: Add authentication (API Key or Cognito)
- [ ] Day 2: Enable CORS
- [ ] Day 3: Implement request/response mapping
- [ ] Day 4: Add stages (dev, staging, prod)
- [ ] Day 5: Learn about API Gateway usage plans
- [ ] Day 6: Explore Lambda layers
- [ ] Day 7: Practice exercises 7-9

---

## Quick Reference

### CloudFormation Template Snippet - Lambda
```yaml
MyFunction:
  Type: AWS::Lambda::Function
  Properties:
    FunctionName: my-function
    Runtime: python3.9
    Handler: index.lambda_handler
    Role: !GetAtt ExecutionRole.Arn
    Code:
      ZipFile: |
        def lambda_handler(event, context):
            return {'statusCode': 200, 'body': 'Hello'}
```

### CloudFormation Template Snippet - API Gateway
```yaml
MyApi:
  Type: AWS::ApiGateway::RestApi
  Properties:
    Name: my-api

MyResource:
  Type: AWS::ApiGateway::Resource
  Properties:
    RestApiId: !Ref MyApi
    ParentId: !GetAtt MyApi.RootResourceId
    PathPart: myresource

MyMethod:
  Type: AWS::ApiGateway::Method
  Properties:
    HttpMethod: GET
    Integration:
      Type: AWS_PROXY
      Uri: !Sub 'arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${MyFunction.Arn}/invocations'
```

### Lambda Event Structure (API Gateway Proxy)
```python
{
    'resource': '/hello',
    'httpMethod': 'GET',
    'queryStringParameters': {'name': 'value'},
    'body': '...',
    'headers': {...},
    'requestContext': {...}
}
```

### Lambda Response Structure (API Gateway Proxy)
```python
{
    'statusCode': 200,
    'headers': {'Content-Type': 'application/json'},
    'body': json.dumps({'message': 'Hello'})
}
```

### Useful Environment Variables
```bash
# For local testing with floci
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

# For AWS deployment
aws configure  # Sets up ~/.aws/credentials
```

---

## Resources

### Official Documentation
- **API Gateway**: https://docs.aws.amazon.com/apigateway/
- **Lambda**: https://docs.aws.amazon.com/lambda/
- **CloudFormation**: https://docs.aws.amazon.com/cloudformation/
- **floci**: https://floci.io

### Tutorials
- AWS API Gateway Developer Guide
- AWS Lambda Getting Started
- CloudFormation User Guide

### Tools
- **AWS CLI**: https://aws.amazon.com/cli/
- **AWS SAM**: https://aws.amazon.com/serverless/sam/
- **floci**: https://github.com/floci-io/floci

### Community
- AWS Developer Forums
- Stack Overflow - tag: [aws-api-gateway], [aws-lambda]
- r/aws on Reddit

---

**Tip**: Always test locally with floci before deploying to AWS to save costs and iterate faster!
