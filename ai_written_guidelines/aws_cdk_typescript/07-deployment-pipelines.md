# Deployment Pipelines

## CDK Pipelines

CDK Pipelines is a high-level construct library for building CI/CD pipelines using **AWS CodePipeline**. It self-mutates — the pipeline definition lives in your CDK app and automatically updates the pipeline.

### Basic Pipeline

```typescript
import { Stack, StackProps } from "aws-cdk-lib";
import { Construct } from "constructs";
import * as pipelines from "aws-cdk-lib/pipelines";
import * as codecommit from "aws-cdk-lib/aws-codecommit";

export class PipelineStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    const repo = codecommit.Repository.fromRepositoryName(
      this, "Repo", "my-cdk-app"
    );

    const pipeline = new pipelines.CodePipeline(this, "Pipeline", {
      pipelineName: "MyAppPipeline",
      synth: new pipelines.ShellStep("Synth", {
        input: pipelines.CodePipelineSource.codeCommit(repo, "main"),
        commands: [
          "npm ci",
          "npm run build",
          "npx cdk synth",
        ],
      }),
    });
  }
}
```

## Multi-Environment Pipeline

```typescript
const pipeline = new pipelines.CodePipeline(this, "Pipeline", {
  pipelineName: "MyAppPipeline",
  synth: new pipelines.ShellStep("Synth", {
    input: pipelines.CodePipelineSource.gitHub("owner/repo", "main"),
    commands: ["npm ci", "npm run build", "npx cdk synth"],
  }),
});

// Pre-production deployment
const devStage = new DevStage(this, "Dev", {
  env: { account: "111111111111", region: "us-east-1" },
});
const dev = pipeline.addStage(devStage);
dev.addPre(new pipelines.ManualApprovalStep("PromoteToStaging"));

// Production deployment
const prodStage = new ProdStage(this, "Prod", {
  env: { account: "222222222222", region: "eu-west-1" },
});
pipeline.addStage(prodStage);
```

## Defining Application Stages

Define stages as separate `Stage` constructs:

```typescript
import { Stage, StageProps } from "aws-cdk-lib";
import { MyStack } from "./my-stack";

export class DevStage extends Stage {
  constructor(scope: Construct, id: string, props?: StageProps) {
    super(scope, id, props);

    new MyStack(this, "MyApp", {
      env: props.env,
      stageName: "dev",
    });
  }
}
```

## Adding Tests to Pipeline

```typescript
const stage = pipeline.addStage(new DevStage(this, "Dev"));

// Unit tests run at synth time
// Integration tests run after deployment
stage.addPost(new pipelines.ShellStep("IntegrationTests", {
  commands: [
    "npm run test:integration",
  ],
  // Optionally use envFromCfnOutputs to pass stack outputs
  envFromCfnOutputs: {
    API_URL: /* stack output */,
  },
}));
```

## GitHub Actions Integration (Alternative)

If you don't use CodePipeline:

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
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
      - run: npx cdk synth
      - run: npx cdk deploy --require-approval never
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: us-east-1
```

## Manual Approvals

```typescript
stage.addPre(new pipelines.ManualApprovalStep("ApproveProd"));
```

## Rollback Strategy

CDK Pipelines handles rollbacks automatically via CloudFormation. For custom rollback behavior:

```typescript
pipeline.addStage(stage, {
  stackSteps: [
    {
      stack: myStack,
      changeSet: [new pipelines.ManualApprovalStep("ReviewChanges")],
    },
  ],
});
```

## Environment-Specific Configuration

Pass configuration via context or props:

```typescript
// App entry point
const app = new cdk.App();

new PipelineStack(app, "PipelineStack", {
  env: { account: "111111111111", region: "us-east-1" },
});

app.synth();

// Stage construct receives config
const config = {
  dev: { instanceType: "t3.small", maxAzs: 2 },
  prod: { instanceType: "t3.large", maxAzs: 3 },
};

class AppStage extends Stage {
  constructor(scope: Construct, id: string, props: StageProps & { config: typeof config.dev }) {
    super(scope, id, props);
    new MyStack(this, "App", { ...props, ...props.config });
  }
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
