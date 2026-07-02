# Core Concepts

## App

The **App** is the root container. It holds one or more stacks.

```python
import aws_cdk as cdk
from my_cdk_app.my_stack import MyStack

app = cdk.App()
MyStack(app, "MyStack",
    env=cdk.Environment(account="123456789012", region="us-east-1"),
)
app.synth()
```

- One app per CDK project
- The entry point (`app.py`) creates the app and instantiates stacks

## Stack

A **Stack** is a deployable unit — it maps to one CloudFormation stack.

```python
from aws_cdk import Stack
from constructs import Construct
import aws_cdk.aws_s3 as s3

class MyStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        s3.Bucket(self, "MyBucket",
            versioned=True,
            removal_policy=cdk.RemovalPolicy.DESTROY,
        )
```

Best practices:
- Split large stacks by concern (networking, compute, data)
- Use `**kwargs` to pass `StackProps` through `super().__init__`
- Use keyword arguments for all props (Python style)

## Construct

A **Construct** is the basic building block. Every AWS resource is a construct.

```python
from constructs import Construct
import aws_cdk.aws_lambda as lambda_

class MyFunction(Construct):
    def __init__(self, scope: Construct, construct_id: str, *,
                 function_name: str,
                 memory_size: int = 128) -> None:
        super().__init__(scope, construct_id)

        self.function = lambda_.Function(self, "Lambda",
            function_name=function_name,
            runtime=lambda_.Runtime.NODEJS_20_X,
            handler="index.handler",
            code=lambda_.Code.from_asset("src"),
            memory_size=memory_size,
        )
```

### Construct Levels

| Level | Description | Examples |
|-------|-------------|---------|
| **L1** (Cfn*) | 1:1 mapping to CloudFormation resources | `CfnBucket`, `CfnFunction` |
| **L2** | Higher-level with sensible defaults | `Bucket`, `Function`, `Table` |
| **L3** (Patterns) | Multi-resource solutions | `LambdaRestApi`, `ApplicationLoadBalancedFargateService` |

Always prefer **L2 constructs** over L1. Use L1 only when L2 doesn't expose a needed property.

## Environment

The `Environment` specifies the target AWS account and region.

```python
from aws_cdk import Environment

# Specified explicitly
env = Environment(account="123456789012", region="us-east-1")

# Use current account/region (from AWS CLI profile)
env = Environment(
    account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
    region=os.environ.get("CDK_DEFAULT_REGION"),
)

# Per-environment via context
config = app.node.try_get_context("dev")
env = Environment(account=config["account"], region=config["region"])
```

## Tokens

**Tokens** represent values that aren't known until deploy time (e.g., ARNs, resource names). They are resolved by CloudFormation.

```python
bucket = s3.Bucket(self, "MyBucket")
# bucket.bucket_arn returns a token (string), resolved at deploy time
cdk.CfnOutput(self, "BucketArn", value=bucket.bucket_arn)
```

- Tokens are opaque strings at synth time
- Use `Fn.sub`, `Fn.join`, etc. for string manipulation of tokens
- `Token.as_string()` and `Token.as_number()` for explicit conversion

## Aspects

**Aspects** apply operations to all constructs in a scope — useful for cross-cutting concerns.

```python
from aws_cdk import IAspect, Aspects
from constructs import IConstruct

class BucketEncryptionAspect(IAspect):
    def visit(self, node: IConstruct) -> None:
        if isinstance(node, s3.CfnBucket):
            node.bucket_encryption = s3.CfnBucket.BucketEncryptionProperty(
                server_side_encryption_configuration=[
                    s3.CfnBucket.ServerSideEncryptionRuleProperty(
                        server_side_encryption_by_default=s3.CfnBucket.ServerSideEncryptionByDefaultProperty(
                            sse_algorithm="AES256"
                        )
                    )
                ]
            )

Aspects.of(app).add(BucketEncryptionAspect())
```

## Python-Specific Notes

- Import aliases: `import aws_cdk.aws_s3 as s3`, `import aws_cdk.aws_lambda as lambda_` (trailing underscore avoids shadowing `lambda` keyword)
- All props use **snake_case** keyword arguments (e.g., `removal_policy`, `bucket_name`)
- Use keyword-only arguments (`*`) for construct props to prevent ordering mistakes
- `construct_id` is the second positional argument (Python convention)

## Resources

- [CDK Concepts](https://docs.aws.amazon.com/cdk/v2/guide/core_concepts.html)
- [Construct Hub](https://constructs.dev/)
