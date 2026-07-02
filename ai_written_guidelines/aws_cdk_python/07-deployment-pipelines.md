# Deployment Pipelines

## CDK Pipelines

CDK Pipelines is a high-level construct library for building CI/CD pipelines using **AWS CodePipeline**. It self-mutates — the pipeline definition lives in your CDK app and automatically updates the pipeline.

### Basic Pipeline

```python
import aws_cdk as cdk
from constructs import Construct
import aws_cdk.pipelines as pipelines
import aws_cdk.aws_codecommit as codecommit


class PipelineStack(cdk.Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        repo = codecommit.Repository.from_repository_name(
            self, "Repo", "my-cdk-app"
        )

        pipeline = pipelines.CodePipeline(self, "Pipeline",
            pipeline_name="MyAppPipeline",
            synth=pipelines.ShellStep("Synth",
                input=pipelines.CodePipelineSource.code_commit(repo, "main"),
                commands=[
                    "pip install -r requirements.txt",
                    "pip install -r requirements-dev.txt",
                    "cdk synth",
                ],
            ),
        )
```

## Multi-Environment Pipeline

```python
pipeline = pipelines.CodePipeline(self, "Pipeline",
    pipeline_name="MyAppPipeline",
    synth=pipelines.ShellStep("Synth",
        input=pipelines.CodePipelineSource.git_hub("owner/repo", "main"),
        commands=[
            "pip install -r requirements.txt",
            "cdk synth",
        ],
    ),
)

# Pre-production deployment
dev_stage = DevStage(self, "Dev",
    env=cdk.Environment(account="111111111111", region="us-east-1"),
)
dev = pipeline.add_stage(dev_stage)
dev.add_pre(pipelines.ManualApprovalStep("PromoteToStaging"))

# Production deployment
prod_stage = ProdStage(self, "Prod",
    env=cdk.Environment(account="222222222222", region="eu-west-1"),
)
pipeline.add_stage(prod_stage)
```

## Defining Application Stages

Define stages as separate `Stage` constructs:

```python
import aws_cdk as cdk
from constructs import Construct
from my_cdk_app.my_stack import MyStack


class DevStage(cdk.Stage):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        MyStack(self, "MyApp",
            env=kwargs.get("env"),
            stage_name="dev",
        )
```

## Adding Tests to Pipeline

```python
stage = pipeline.add_stage(DevStage(self, "Dev"))

# Unit tests run at synth time
# Integration tests run after deployment
stage.add_post(pipelines.ShellStep("IntegrationTests",
    commands=[
        "pip install -r requirements-dev.txt",
        "pytest tests/integration/",
    ],
    env_from_cfn_outputs={
        "API_URL": ...,
    },
))
```

## GitHub Actions Integration (Alternative)

```yaml
name: Deploy CDK
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - run: pip install -r requirements-dev.txt
      - run: cdk synth
      - run: cdk deploy --require-approval never
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: us-east-1
```

## Manual Approvals

```python
stage.add_pre(pipelines.ManualApprovalStep("ApproveProd"))
```

## Rollback Strategy

CDK Pipelines handles rollbacks automatically via CloudFormation.

```python
pipeline.add_stage(stage,
    stack_steps=[
        pipelines.StackSteps(
            stack=my_stack,
            change_set=[pipelines.ManualApprovalStep("ReviewChanges")],
        ),
    ],
)
```

## Environment-Specific Configuration

Pass configuration via context or props:

```python
# app.py
app = cdk.App()

PipelineStack(app, "PipelineStack",
    env=cdk.Environment(account="111111111111", region="us-east-1"),
)

app.synth()

# Config loaded from context or dict
class AppStage(cdk.Stage):
    def __init__(self, scope: Construct, construct_id: str, *,
                 config: dict, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        MyStack(self, "App",
            env=kwargs.get("env"),
            instance_type=config["instance_type"],
            max_azs=config["max_azs"],
        )

config = {
    "dev": {"instance_type": "t3.small", "max_azs": 2},
    "prod": {"instance_type": "t3.large", "max_azs": 3},
}
```

## Pipeline Best Practices

| Practice | Detail |
|----------|--------|
| **Self-mutation** | Let the pipeline update itself when the pipeline stack changes |
| **Synth in pipeline** | Run `cdk synth` in the pipeline, not locally |
| **Secrets** | Store in AWS Secrets Manager, not in code or context |
| **Rollback** | CloudFormation handles automatic rollback on failure |
| **Approval gates** | Add manual approval before production deployment |
| **Cross-account** | Bootstrap each target account and region before deploying |

## Bootstrap for Pipelines

Pipelines require cross-account bootstrapping:

```bash
# Bootstrap the pipeline account
cdk bootstrap aws://PIPELINE-ACCOUNT/us-east-1

# Bootstrap each target environment
cdk bootstrap aws://DEV-ACCOUNT/us-east-1
cdk bootstrap aws://PROD-ACCOUNT/eu-west-1 \
  --trust PIPELINE-ACCOUNT \
  --cloudformation-execution-policies arn:aws:iam::aws:policy/AdministratorAccess
```

## Resources

- [CDK Pipelines Documentation](https://docs.aws.amazon.com/cdk/v2/guide/cdk_pipeline.html)
- [CDK Pipelines API Reference](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-cdk-lib.pipelines-readme.html)
