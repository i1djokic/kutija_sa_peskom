# Best Practices

## Project Structure

```
my_cdk_app/
├── stacks/
│   ├── __init__.py
│   ├── network_stack.py         # VPC, subnets, NAT
│   ├── database_stack.py        # RDS, DynamoDB, ElastiCache
│   ├── compute_stack.py         # Lambda, ECS, EKS
│   └── api_stack.py             # API Gateway, CloudFront
├── constructs/
│   ├── __init__.py
│   ├── api_lambda.py            # Reusable API Lambda pattern
│   ├── secure_bucket.py         # Bucket with enforced encryption
│   └── scheduled_task.py        # EventBridge + Lambda pattern
├── utils/
│   ├── __init__.py
│   ├── naming.py                # Consistent resource naming
│   └── constants.py             # Environment configs
├── __init__.py
└── my_app.py                    # Stack definitions (optional)
```

## Construct Design

### Favor Composition Over Inheritance

```python
# ✅ Composition
class SecureBucket(Construct):
    def __init__(self, scope: Construct, construct_id: str, *,
                 encryption: s3.BucketEncryption = s3.BucketEncryption.S3_MANAGED,
                 **kwargs) -> None:
        super().__init__(scope, construct_id)

        self.bucket = s3.Bucket(self, "InnerBucket",
            encryption=encryption,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            enforce_ssl=True,
            **kwargs,
        )

# ❌ Inheritance (avoids auto-generated logical IDs)
class SecureBucket(s3.Bucket):
    # Not recommended
    pass
```

### Expose Meaningful Properties

```python
class ApiLambda(Construct):
    def __init__(self, scope: Construct, construct_id: str, *,
                 function_name: str) -> None:
        super().__init__(scope, construct_id)

        self.api: apigateway.LambdaRestApi
        self.function: lambda_.Function
        # ...
```

Use type hints on exposed properties for IDE autocompletion.

## Stack Organization

### One Concern Per Stack

```python
# ✅ Split by concern
NetworkStack(app, "NetworkStack", env=env)
DatabaseStack(app, "DatabaseStack", env=env)
ComputeStack(app, "ComputeStack", env=env)

# ❌ Single monolithic stack
MonolithStack(app, "MonolithStack", env=env)
```

### Use Typed Props for Stack Configuration

```python
from dataclasses import dataclass


@dataclass
class AppStackProps:
    vpc: ec2.IVpc
    database: dynamodb.ITable
    stage_name: str


class AppStack(cdk.Stack):
    def __init__(self, scope: Construct, construct_id: str, *,
                 config: AppStackProps, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        # Use config.vpc, config.database, etc.
```

## Configuration Management

### Use Context, Not Hardcoded Values

```json
// cdk.json
{
  "context": {
    "dev": {
      "instance_type": "t3.small",
      "min_capacity": 1
    },
    "prod": {
      "instance_type": "t3.large",
      "min_capacity": 3
    }
  }
}
```

```python
# Access context
stage = app.node.try_get_context("stage")
config = app.node.try_get_context(stage)
```

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| Construct ID | PascalCase | `MyBucket`, `ApiLambda` |
| Stack name | PascalCase + `Stack` suffix | `NetworkStack`, `ApiStack` |
| Logical ID | Auto-generated (do not override) | — |
| Physical name | Let CDK auto-generate (or use `cdk-nag`) | — |
| File names | snake_case | `secure_bucket.py`, `network_stack.py` |
| Class names | PascalCase | `SecureBucket`, `NetworkStack` |

## Removal Policies

```python
# Development stacks — allow cleanup
removal_policy=cdk.RemovalPolicy.DESTROY,
auto_delete_objects=True,

# Production stacks — protect data
removal_policy=cdk.RemovalPolicy.RETAIN,
# No auto_delete_objects
```

## Tagging

Apply tags for cost tracking and resource management:

```python
from aws_cdk import Tags

Tags.of(app).add("Environment", "production")
Tags.of(app).add("Project", "my-app")
Tags.of(app).add("CostCenter", "12345")

# Override at stack level
Tags.of(stack).add("Environment", "dev")
```

## Security

| Rule | Rationale |
|------|-----------|
| Use `grant_*` methods instead of raw IAM policies | Auto-generates least-privilege policies |
| Enable S3 encryption by default | Data protection at rest |
| Enable DynamoDB encryption | Data protection at rest |
| Use `secretsmanager.Secret` instead of env vars | Secrets are encrypted and auditable |
| Set `removal_policy: RETAIN` in production | Prevents accidental data loss |
| Avoid hardcoded account/region | Use `CDK_DEFAULT_ACCOUNT` and `CDK_DEFAULT_REGION` |

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Monolithic stack | Slow deploy, hard to reason about | Split by concern |
| Overriding logical IDs | Breaks CloudFormation updates | Let CDK auto-generate |
| Hardcoding ARNs | Fragile, not portable | Use `from_{resource}_arn()` methods |
| Using `Fn.ref` directly | Bypasses CDK's type safety | Use L2 construct properties |
| Ignoring `cdk diff` | Surprises on deploy | Always run `cdk diff` before deploy |
| Missing `__init__.py` | Python package not importable | Add empty `__init__.py` to all subdirs |
| Forgetting `self` in lambda | Runtime reference error | Always pass `self` as first arg to methods |

## CDK Nag (Security Linting)

```bash
pip install cdk-nag
```

```python
from cdk_nag import AwsSolutionsChecks, NagSuppressions

# Apply to entire app
cdk.Aspects.of(app).add(AwsSolutionsChecks())

# Suppress specific rule
NagSuppressions.add_stack_suppressions(stack, [
    {
        "id": "AwsSolutions-S1",
        "reason": "Access logs not required for dev",
    },
])
```

## Python-Specific Best Practices

| Practice | Detail |
|----------|--------|
| Use `__init__.py` in every package directory | Ensures Python can import modules |
| Use type hints (`: type`, `-> ReturnType`) | Catches errors with mypy |
| Use keyword-only arguments (`*`) for construct props | Prevents positional argument confusion |
| Use `lambda_` alias instead of `lambda` | Avoids shadowing built-in keyword |
| Group imports: stdlib → third-party → CDK | Standard Python import ordering |
| Run `black` and `ruff` before commit | Consistent formatting and linting |

## Resources

- [CDK Best Practices](https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html)
- [cdk-nag](https://github.com/cdklabs/cdk-nag)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
