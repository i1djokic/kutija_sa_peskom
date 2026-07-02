# IAM & Security

## How CDK Handles IAM

CDK automatically generates IAM policies based on resource usage. In most cases, you don't write raw IAM policies — CDK infers the minimum required permissions from method calls.

```python
bucket = s3.Bucket(self, "MyBucket")
fn = lambda_.Function(self, "MyFunction", ...)

# CDK automatically adds s3:GetObject, s3:PutObject, etc. to fn's role
bucket.grant_read_write(fn)
```

## Grant Methods

Each resource exposes grant methods that auto-generate IAM policies:

| Method | Effect |
|--------|--------|
| `bucket.grant_read(principal)` | `s3:GetObject`, `s3:ListBucket` |
| `bucket.grant_write(principal)` | `s3:PutObject`, `s3:DeleteObject` |
| `bucket.grant_read_write(principal)` | Both read + write |
| `bucket.grant_put(principal)` | `s3:PutObject` |
| `table.grant_read_data(principal)` | `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan` |
| `table.grant_write_data(principal)` | `dynamodb:PutItem`, `dynamodb:UpdateItem`, `dynamodb:DeleteItem` |
| `table.grant_read_write_data(principal)` | Both read + write |
| `queue.grant_send_messages(principal)` | `sqs:SendMessage` |
| `queue.grant_consume_messages(principal)` | `sqs:ReceiveMessage`, `sqs:DeleteMessage` |
| `topic.grant_publish(principal)` | `sns:Publish` |
| `function.grant_invoke(principal)` | `lambda:InvokeFunction` |

## IAM Roles

### Creating a Role

```python
import aws_cdk.aws_iam as iam

role = iam.Role(self, "MyRole",
    assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
    description="Custom role for Lambda execution",
    managed_policies=[
        iam.ManagedPolicy.from_aws_managed_policy_name(
            "service-role/AWSLambdaBasicExecutionRole"
        ),
    ],
)
```

### Inline Policies

```python
role.add_to_policy(iam.PolicyStatement(
    actions=["kms:Decrypt", "kms:Encrypt"],
    resources=[key.key_arn],
))
```

### Custom Managed Policies

```python
policy = iam.ManagedPolicy(self, "MyPolicy",
    statements=[
        iam.PolicyStatement(
            effect=iam.Effect.ALLOW,
            actions=["ec2:DescribeInstances"],
            resources=["*"],
        ),
    ],
)
role.add_managed_policy(policy)
```

## Principle of Least Privilege

Always grant the minimum permissions needed:

```python
# ❌ Too broad
bucket.grant_read_write(fn)

# ✅ Just what's needed
bucket.grant_read(fn)         # Only read access
```

## Cross-Stack Permissions

When resources are in different stacks:

```python
# infra_stack.py
bucket = s3.Bucket(self, "MyBucket")

# app_stack.py — receive bucket via props
class AppStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, *,
                 bucket: s3.IBucket, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        fn = lambda_.Function(self, "MyFunction", ...)
        bucket.grant_read(fn)

# app.py — connect stacks
infra = InfraStack(app, "InfraStack")
app_stack = AppStack(app, "AppStack", bucket=infra.bucket)
app_stack.add_dependency(infra)
```

## Security Best Practices

### Encryption at Rest

```python
# S3 SSE-S3
bucket = s3.Bucket(self, "MyBucket",
    encryption=s3.BucketEncryption.S3_MANAGED,
)

# S3 SSE-KMS
bucket = s3.Bucket(self, "MyBucket",
    encryption=s3.BucketEncryption.KMS,
    encryption_key=kms.Key(self, "MyKey"),
)

# DynamoDB encryption (default is AWS owned)
table = dynamodb.Table(self, "MyTable",
    encryption=dynamodb.TableEncryption.AWS_MANAGED,
)
```

### Encryption in Transit

```python
# CloudFront forces HTTPS
cloudfront.Distribution(self, "Distribution",
    default_behavior=cloudfront.BehaviorOptions(
        origin=origins.S3Origin(bucket),
        viewer_protocol_policy=cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    ),
)
```

### Secrets and Environment Variables

Never hardcode secrets:

```python
# ❌ Never
fn = lambda_.Function(self, "Fn",
    environment={"DB_PASSWORD": "hunter2"},
)

# ✅ Use Secrets Manager
secret = secretsmanager.Secret.from_secret_name_v2(
    self, "DbSecret", "prod/db"
)
fn.add_environment("DB_PASSWORD", secret.secret_value.to_string())

# ✅ Use SSM Parameter Store
param = ssm.StringParameter.from_secure_string_parameter_attributes(
    self, "DbParam",
    parameter_name="/prod/db/password",
)
fn.add_environment("DB_PASSWORD", param.string_value)
```

## Common IAM Patterns

| Pattern | Solution |
|---------|----------|
| Lambda reads from S3 | `bucket.grant_read(lambda_fn)` |
| Lambda writes to DynamoDB | `table.grant_write_data(lambda_fn)` |
| API Gateway invokes Lambda | Automatic with `LambdaIntegration` |
| Lambda sends to SQS | `queue.grant_send_messages(lambda_fn)` |
| Cross-account access | Use `iam.AccountPrincipal` in resource policy |
| Service-to-service | `role.add_to_policy(...)` |

## Resources

- [CDK IAM Module](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-iam-readme.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
