# Testing

CDK tests verify that your infrastructure code produces the expected CloudFormation templates. They run at **synth time** — no AWS credentials needed.

## Test Setup

Install test dependencies:

```bash
pip install pytest pytest-cov
```

Create `tests/unit/test_my_stack.py`:

## Fine-Grained Assertions (Recommended)

Use `aws_cdk.assertions` (built into `aws-cdk-lib`) for fine-grained assertions:

```python
import aws_cdk as cdk
from aws_cdk.assertions import Template
import aws_cdk.aws_s3 as s3


def test_s3_bucket_has_encryption():
    app = cdk.App()
    stack = cdk.Stack(app, "TestStack")

    s3.Bucket(stack, "MyBucket",
        encryption=s3.BucketEncryption.S3_MANAGED,
    )

    template = Template.from_stack(stack)

    template.has_resource_properties("AWS::S3::Bucket", {
        "BucketEncryption": {
            "ServerSideEncryptionConfiguration": [
                {
                    "ServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256",
                    },
                },
            ],
        },
    })
```

## Count Assertions

Assert on the number of resources:

```python
# Exactly 1 bucket
template.resource_count_is("AWS::S3::Bucket", 1)

# At least 1 Lambda
template.find_resources("AWS::Lambda::Function")
```

## Specific Value Assertions

```python
template.has_resource_properties("AWS::DynamoDB::Table", {
    "BillingMode": "PAY_PER_REQUEST",
    "KeySchema": [
        {"AttributeName": "pk", "KeyType": "HASH"},
    ],
})
```

## Snapshot Testing

Snapshot tests capture the full synthesized template:

```python
def test_stack_matches_snapshot(snapshot):
    app = cdk.App()
    stack = MyStack(app, "TestStack")

    template = Template.from_stack(stack)
    assert template.to_json() == snapshot
```

For pytest snapshot support, install `syrupy`:

```bash
pip install syrupy
```

```python
# conftest.py
from syrupy import SnapshotAssertion

# test file
def test_snapshot(snapshot: SnapshotAssertion):
    app = cdk.App()
    stack = MyStack(app, "TestStack")
    template = Template.from_stack(stack)
    assert snapshot == template.to_json()
```

Update snapshots:

```bash
pytest --snapshot-update
```

## Testing IAM Permissions

```python
import aws_cdk as cdk
from aws_cdk.assertions import Template, Match
import aws_cdk.aws_s3 as s3
import aws_cdk.aws_lambda as lambda_


def test_lambda_has_s3_read_access():
    app = cdk.App()
    stack = cdk.Stack(app, "TestStack")

    bucket = s3.Bucket(stack, "MyBucket")
    fn = lambda_.Function(stack, "MyFunction",
        runtime=lambda_.Runtime.NODEJS_20_X,
        handler="index.handler",
        code=lambda_.Code.from_inline(
            "def handler(event, context): return {'statusCode': 200}"
        ),
    )
    bucket.grant_read(fn)

    template = Template.from_stack(stack)

    template.has_resource_properties("AWS::IAM::Policy", {
        "PolicyDocument": {
            "Statement": Match.array_with([
                Match.object_like({
                    "Action": ["s3:GetObject*", "s3:GetBucket*", "s3:List*"],
                    "Effect": "Allow",
                }),
            ]),
        },
    })
```

## Testing with Context

```python
app = cdk.App(context={"environment": "test"})
stack = MyStack(app, "TestStack",
    env=cdk.Environment(account="123456789012", region="us-east-1"),
)
```

## Test Patterns

### Pytest Fixtures

```python
import pytest
import aws_cdk as cdk
from aws_cdk.assertions import Template


@pytest.fixture
def stack():
    app = cdk.App()
    return cdk.Stack(app, "TestStack",
        env=cdk.Environment(account="123456789012", region="us-east-1"),
    )


@pytest.fixture
def template(stack):
    return Template.from_stack(stack)


def test_bucket_created(template):
    template.resource_count_is("AWS::S3::Bucket", 1)
```

### Testing Custom Constructs

```python
def test_my_construct_creates_lambda():
    app = cdk.App()
    stack = cdk.Stack(app, "TestStack")

    MyConstruct(stack, "TestConstruct", function_name="test-fn")

    template = Template.from_stack(stack)
    template.has_resource_properties("AWS::Lambda::Function", {
        "Runtime": "nodejs20.x",
    })
```

## Testing Against Deployed Resources (Integ Tests)

For full end-to-end testing:

```python
from aws_cdk.integ_tests import IntegTest

app = cdk.App()
stack = MyStack(app, "IntegStack")

IntegTest(app, "MyIntegTest",
    test_cases=[stack],
    regions=["us-east-1"],
)

app.synth()
```

## Running Tests

```bash
# Run all tests
pytest

# With coverage
pytest --cov=my_cdk_app

# Update snapshots
pytest --snapshot-update

# Verbose output
pytest -v
```

## Resources

- [CDK Assertions Documentation](https://docs.aws.amazon.com/cdk/v2/guide/testing.html)
- [Pytest Documentation](https://docs.pytest.org/)
- [Syrupy (snapshot testing)](https://github.com/tophat/syrupy)
