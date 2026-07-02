# Constructs & Resources

## Import Convention

Import AWS service modules with snake_case aliases:

```python
import aws_cdk as cdk
import aws_cdk.aws_s3 as s3
import aws_cdk.aws_lambda as lambda_
import aws_cdk.aws_apigateway as apigateway
import aws_cdk.aws_dynamodb as dynamodb
import aws_cdk.aws_ec2 as ec2
import aws_cdk.aws_iam as iam
import aws_cdk.aws_sqs as sqs
import aws_cdk.aws_sns as sns
import aws_cdk.aws_sns_subscriptions as subscriptions
import aws_cdk.aws_cloudfront as cloudfront
import aws_cdk.aws_cloudfront_origins as origins
import aws_cdk.aws_events as events
import aws_cdk.aws_events_targets as targets
import aws_cdk.aws_kms as kms
import aws_cdk.aws_secretsmanager as secretsmanager
import aws_cdk.aws_ssm as ssm
```

## S3 Bucket

```python
from aws_cdk import RemovalPolicy, Duration

bucket = s3.Bucket(self, "MyBucket",
    versioned=True,
    removal_policy=RemovalPolicy.DESTROY,       # For dev only
    auto_delete_objects=True,                    # Clean up on destroy
    encryption=s3.BucketEncryption.S3_MANAGED,
    block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
    lifecycle_rules=[
        s3.LifecycleRule(expiration=Duration.days(90)),
    ],
)
```

## Lambda Function

```python
import aws_cdk.aws_lambda as lambda_
from aws_cdk import Duration

fn = lambda_.Function(self, "MyFunction",
    runtime=lambda_.Runtime.NODEJS_20_X,
    handler="index.handler",
    code=lambda_.Code.from_asset("dist/lambda"),
    memory_size=256,
    timeout=Duration.seconds(30),
    environment={
        "TABLE_NAME": table.table_name,
    },
    tracing=lambda_.Tracing.ACTIVE,
)
```

### Python Lambda (inline or local code)

```python
# Python runtime with local code
fn = lambda_.Function(self, "MyPythonFunction",
    runtime=lambda_.Runtime.PYTHON_3_12,
    handler="index.handler",
    code=lambda_.Code.from_asset("lambda_src"),
)

# Inline Python code (for small functions)
fn = lambda_.Function(self, "MyInlineFunction",
    runtime=lambda_.Runtime.PYTHON_3_12,
    handler="index.handler",
    code=lambda_.Code.from_inline(
        "def handler(event, context):\n"
        "    return {'statusCode': 200, 'body': 'Hello'}"
    ),
)
```

### Lambda with Docker

```python
lambda_.DockerImageFunction(self, "MyDockerFunction",
    code=lambda_.DockerImageCode.from_image_asset("src/docker-fn"),
    memory_size=1024,
    timeout=Duration.minutes(5),
)
```

## API Gateway (REST)

```python
import aws_cdk.aws_apigateway as apigateway

api = apigateway.LambdaRestApi(self, "MyApi",
    handler=fn,
    proxy=False,
)

items = api.root.add_resource("items")
items.add_method("GET", apigateway.LambdaIntegration(fn))
items.add_method("POST", apigateway.LambdaIntegration(fn))

item = items.add_resource("{id}")
item.add_method("GET", apigateway.LambdaIntegration(fn))
item.add_method("DELETE", apigateway.LambdaIntegration(fn))
```

### API Gateway (HTTP)

```python
import aws_cdk.aws_apigatewayv2 as apigatewayv2
import aws_cdk.aws_apigatewayv2_integrations as integrations

http_api = apigatewayv2.HttpApi(self, "MyHttpApi")
http_api.add_routes(
    path="/items",
    methods=[apigatewayv2.HttpMethod.GET],
    integration=integrations.HttpLambdaIntegration("ItemsIntegration", fn),
)
```

## DynamoDB Table

```python
import aws_cdk.aws_dynamodb as dynamodb

table = dynamodb.Table(self, "MyTable",
    partition_key=dynamodb.Attribute(
        name="pk",
        type=dynamodb.AttributeType.STRING,
    ),
    sort_key=dynamodb.Attribute(
        name="sk",
        type=dynamodb.AttributeType.STRING,
    ),
    billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
    removal_policy=cdk.RemovalPolicy.DESTROY,
    time_to_live_attribute="ttl",
    point_in_time_recovery=True,
)
```

## VPC & Networking

```python
import aws_cdk.aws_ec2 as ec2

vpc = ec2.Vpc(self, "MyVpc",
    max_azs=2,
    nat_gateways=1,
    subnet_configuration=[
        ec2.SubnetConfiguration(
            cidr_mask=24,
            name="public",
            subnet_type=ec2.SubnetType.PUBLIC,
        ),
        ec2.SubnetConfiguration(
            cidr_mask=24,
            name="private",
            subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS,
        ),
    ],
)
```

## SQS Queue

```python
import aws_cdk.aws_sqs as sqs
from aws_cdk import Duration

queue = sqs.Queue(self, "MyQueue",
    visibility_timeout=Duration.seconds(30),
    retention_period=Duration.days(4),
    encryption=sqs.QueueEncryption.SQS_MANAGED,
)
```

## SNS Topic

```python
import aws_cdk.aws_sns as sns
import aws_cdk.aws_sns_subscriptions as subscriptions

topic = sns.Topic(self, "MyTopic")
topic.add_subscription(subscriptions.EmailSubscription("user@example.com"))
```

## CloudFront Distribution

```python
import aws_cdk.aws_cloudfront as cloudfront
import aws_cdk.aws_cloudfront_origins as origins

distribution = cloudfront.Distribution(self, "MyDistribution",
    default_behavior=cloudfront.BehaviorOptions(
        origin=origins.S3Origin(bucket),
        viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    ),
    price_class=cloudfront.PriceClass.PRICE_CLASS_100,
)
```

## EventBridge Rule

```python
import aws_cdk.aws_events as events
import aws_cdk.aws_events_targets as targets
from aws_cdk import Duration

rule = events.Rule(self, "ScheduleRule",
    schedule=events.Schedule.rate(Duration.hours(1)),
)
rule.add_target(targets.LambdaFunction(fn))
```

## L3 Patterns (Multi-Resource)

```python
import aws_cdk.aws_apigateway as apigateway
import aws_cdk.aws_ecs_patterns as ecs_patterns

# API Gateway + Lambda
apigateway.LambdaRestApi(self, "Api", handler=fn)

# ECS Fargate + ALB
ecs_patterns.ApplicationLoadBalancedFargateService(self, "Service",
    task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
        image=ecs.ContainerImage.from_asset("src/app"),
    ),
)
```

## CloudFormation Outputs

```python
from aws_cdk import CfnOutput

CfnOutput(self, "BucketName",
    value=bucket.bucket_name,
    description="S3 bucket name",
    export_name=f"{self.stack_name}-BucketName",
)
```

## Python-Specific Notes

- All property names are **snake_case** (e.g., `removal_policy`, `bucket_name`, `block_public_access`)
- Import `lambda_` avoids shadowing Python's built-in `lambda` keyword
- Enum values use `ClassName.MEMBER` syntax (e.g., `s3.BucketEncryption.S3_MANAGED`)
- Dictionaries for mapping/props use `{}`, not type constructors
- Use `from_asset()`, `from_inline()`, `from_bucket()` — static factory methods with snake_case

## Resources

- [CDK Construct Library](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [Construct Hub](https://constructs.dev/)
