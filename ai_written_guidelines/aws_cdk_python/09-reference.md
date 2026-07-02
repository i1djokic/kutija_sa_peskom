# CLI & API Reference

## CDK CLI Commands

| Command | Description |
|---------|-------------|
| `cdk init app --language python` | Scaffold a new CDK Python project |
| `cdk synth [stack]` | Generate CloudFormation template(s) |
| `cdk deploy [stack]` | Deploy stack(s) to AWS |
| `cdk diff [stack]` | Compare deployed stack with local |
| `cdk destroy [stack]` | Delete stack(s) |
| `cdk list` | List stacks in the app |
| `cdk bootstrap [env]` | Prepare environment for CDK deployments |
| `cdk doctor` | Check CDK installation and environment |
| `cdk metadata [stack]` | Show metadata about a stack |
| `cdk context` | Manage CDK context values |

### Common Flags

| Flag | Description |
|------|-------------|
| `--profile PROFILE` | Use named AWS CLI profile |
| `--require-approval [never\|any\|broadening]` | Approval level for IAM changes |
| `--outputs-file FILE` | Write stack outputs to JSON file |
| `--toolkit-stack-name NAME` | Custom bootstrap stack name |
| `--app COMMAND` | Override app command from `cdk.json` |
| `--context KEY=VALUE` | Add runtime context |
| `--verbose` | Verbose output |

## Common Imports

```python
import aws_cdk as cdk
from aws_cdk import (
    App, Stack, Duration, RemovalPolicy, CfnOutput,
    Environment,
)
from constructs import Construct
import aws_cdk.aws_s3 as s3
import aws_cdk.aws_lambda as lambda_
import aws_cdk.aws_lambda_python_alpha as lambda_python
import aws_cdk.aws_apigateway as apigateway
import aws_cdk.aws_apigatewayv2 as apigatewayv2
import aws_cdk.aws_apigatewayv2_integrations as apigw_integrations
import aws_cdk.aws_dynamodb as dynamodb
import aws_cdk.aws_ec2 as ec2
import aws_cdk.aws_ecs as ecs
import aws_cdk.aws_ecs_patterns as ecs_patterns
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
import aws_cdk.aws_route53 as route53
import aws_cdk.aws_route53_targets as r53_targets
import aws_cdk.aws_certificatemanager as certificatemanager
import aws_cdk.aws_codecommit as codecommit
import aws_cdk.aws_codebuild as codebuild
import aws_cdk.pipelines as pipelines

# Testing
from aws_cdk.assertions import Template, Match
```

## Quick Reference

### App Structure

```python
app = cdk.App()
MyStack(app, "MyStack",
    env=cdk.Environment(account="123456789012", region="us-east-1"),
)
app.synth()
```

### Stack Structure

```python
class MyStack(cdk.Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        # Define resources here
```

### Custom Construct Structure

```python
class MyConstruct(Construct):
    def __init__(self, scope: Construct, construct_id: str, *,
                 # keyword-only props here
                 ) -> None:
        super().__init__(scope, construct_id)
        # Define resources here
```

### Grant Methods Quick Reference

```python
s3.Bucket:
    .grant_read(principal)          # s3:GetObject, s3:ListBucket
    .grant_write(principal)         # s3:PutObject, s3:DeleteObject
    .grant_read_write(principal)    # Both
    .grant_put(principal)           # s3:PutObject

dynamodb.Table:
    .grant_read_data(principal)     # GetItem, Query, Scan
    .grant_write_data(principal)    # PutItem, UpdateItem, DeleteItem
    .grant_read_write_data(principal)
    .grant_full_access(principal)

lambda_.Function:
    .grant_invoke(principal)        # lambda:InvokeFunction

sqs.Queue:
    .grant_send_messages(principal)
    .grant_consume_messages(principal)
    .grant_purge(principal)

sns.Topic:
    .grant_publish(principal)
```

### Duration Helpers

```python
Duration.seconds(30)
Duration.minutes(5)
Duration.hours(1)
Duration.days(7)
Duration.millis(500)
```

### Removal Policies

```python
cdk.RemovalPolicy.DESTROY     # Delete resource on stack deletion
cdk.RemovalPolicy.RETAIN      # Retain resource on stack deletion (default)
cdk.RemovalPolicy.SNAPSHOT    # Snapshot before deletion (RDS, EFS)
```

### Lambda Runtimes

```python
lambda_.Runtime.NODEJS_20_X
lambda_.Runtime.NODEJS_18_X
lambda_.Runtime.PYTHON_3_12
lambda_.Runtime.PYTHON_3_11
lambda_.Runtime.JAVA_21
lambda_.Runtime.JAVA_17
lambda_.Runtime.DOTNET_8
lambda_.Runtime.GO_1_X
lambda_.Runtime.RUBY_3_2
lambda_.Runtime.PROVIDED_AL2023
```

## Common Escape Hatches

When L2 constructs don't expose a property you need:

### Raw CloudFormation Property

```python
bucket = s3.Bucket(self, "MyBucket")
cfn_bucket = bucket.node.default_child  # Returns CfnBucket
cfn_bucket.add_property_override("ObjectLockEnabled", True)
```

### Raw CloudFormation Resource

```python
# When no L2 exists
from aws_cdk import CfnResource

CfnResource(self, "MyCustomResource",
    type="AWS::Service::Resource",
    properties={...},
)
```

### Raw IAM Policy Statement

```python
fn.add_to_role_policy(iam.PolicyStatement(
    actions=["custom:Action"],
    resources=["*"],
))
```

## CDK Version Compatibility

```bash
# Check current version
cdk --version

# Upgrade CDK CLI
npm install -g aws-cdk@latest

# Upgrade library in project
pip install --upgrade aws-cdk-lib constructs

# Check installed versions
pip show aws-cdk-lib
```

## Python Development Commands

```bash
# Activate virtual environment
source .venv/bin/activate

# Install all dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Run tests
pytest -v

# Type check
mypy app.py my_cdk_app/

# Format code
black my_cdk_app/ tests/

# Lint
ruff check my_cdk_app/ tests/
```

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `ModuleNotFoundError: No module named 'aws_cdk'` | Virtual env not activated | `source .venv/bin/activate` |
| `Resource X does not exist` | Bootstrap missing | `cdk bootstrap` |
| `Access denied` | IAM permissions insufficient | Check AWS CLI profile permissions |
| `Stack deployment timeout` | Resource taking too long | Increase CloudFormation timeout |
| `No Such Bucket` during synth | Bootstrap bucket missing | `cdk bootstrap` |
| `Context value not found` | Missing context in `cdk.json` | Add or run `cdk context --reset` |
| `Nested stack limit exceeded` | Too many nested stacks | Split stacks further |
| `SyntaxError` in CDK code | Python version too old | Use Python >= 3.8 |

## Resources

- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [CDK CLI Reference](https://docs.aws.amazon.com/cdk/v2/guide/cli.html)
- [Construct Hub](https://constructs.dev/)
- [AWS CDK Python Examples](https://github.com/aws-samples/aws-cdk-examples/tree/master/python)
