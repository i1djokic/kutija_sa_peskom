# Core Concepts

## App

The **App** is the root container. It holds one or more stacks.

```typescript
import { App } from "aws-cdk-lib";
import { MyStack } from "../lib/my-stack";

const app = new App();
new MyStack(app, "MyStack", {
  env: { account: "123456789012", region: "us-east-1" },
});
app.synth();
```

- One app per CDK project
- The entry point in `bin/` creates the app and instantiates stacks

## Stack

A **Stack** is a deployable unit — it maps to one CloudFormation stack.

```typescript
import { Stack, StackProps } from "aws-cdk-lib";
import { Construct } from "constructs";
import * as s3 from "aws-cdk-lib/aws-s3";

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    new s3.Bucket(this, "MyBucket", {
      versioned: true,
      removalPolicy: RemovalPolicy.DESTROY,
    });
  }
}
```

Best practices:
- Split large stacks by concern (networking, compute, data)
- Use `StackProps` interface for configuration
- Set `env` at the app level, not inside the stack

## Construct

A **Construct** is the basic building block. Every AWS resource is a construct.

```typescript
import { Construct } from "constructs";
import * as lambda from "aws-cdk-lib/aws-lambda";

export interface MyFunctionProps {
  functionName: string;
  memorySize?: number;
}

export class MyFunction extends Construct {
  public readonly function: lambda.Function;

  constructor(scope: Construct, id: string, props: MyFunctionProps) {
    super(scope, id);

    this.function = new lambda.Function(this, "Lambda", {
      functionName: props.functionName,
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: "index.handler",
      code: lambda.Code.fromAsset("src"),
      memorySize: props.memorySize ?? 128,
    });
  }
}
```

### Construct Levels

| Level | Description | Examples |
|-------|-------------|---------|
| **L1** (Cfn*) | 1:1 mapping to CloudFormation resources | `CfnBucket`, `CfnFunction` |
| **L2** | Higher-level with sensible defaults | `Bucket`, `Function`, `Table` |
| **L3** (Patterns) | Multi-resource solutions | `LambdaRestApi`, `ApplicationLoadBalancedFargateService` |

Always prefer **L2 constructs** over L1. Use L1 only when L2 doesn't expose a needed property.

## Environment

The `env` specifies the target AWS account and region.

```typescript
// Specified explicitly
env: { account: "123456789012", region: "us-east-1" }

// Use current account/region (from AWS CLI profile)
env: { account: process.env.CDK_DEFAULT_ACCOUNT, region: process.env.CDK_DEFAULT_REGION }

// Per-environment via context
const account = app.node.tryGetContext("account");
const region = app.node.tryGetContext("region");
```

## Tokens

**Tokens** represent values that aren't known until deploy time (e.g., ARNs, resource names). They are resolved by CloudFormation.

```typescript
const bucket = new s3.Bucket(this, "MyBucket");
// bucket.bucketArn returns a token (string), resolved at deploy time
new CfnOutput(this, "BucketArn", { value: bucket.bucketArn });
```

- Tokens are opaque strings at synth time
- Use `Fn.sub`, `Fn.join`, etc. for string manipulation of tokens
- `Token.asString()` and `Token.asNumber()` for explicit conversion

## Aspects

**Aspects** apply operations to all constructs in a scope — useful for cross-cutting concerns.

```typescript
import { IAspect, Aspects } from "aws-cdk-lib";

class BucketEncryptionAspect implements IAspect {
  visit(node: IConstruct) {
    if (node instanceof s3.CfnBucket) {
      node.bucketEncryption = {
        serverSideEncryptionConfiguration: [
          { serverSideEncryptionByDefault: { sseAlgorithm: "AES256" } },
        ],
      };
    }
  }
}

Aspects.of(app).add(new BucketEncryptionAspect());
```

## Resource

- [CDK Concepts](https://docs.aws.amazon.com/cdk/v2/guide/core_concepts.html)
- [Construct Hub](https://constructs.dev/)
