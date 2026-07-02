# CLI & API Reference

## CDK CLI Commands

| Command | Description |
|---------|-------------|
| `cdk init app --language typescript` | Scaffold a new CDK TypeScript project |
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
| `--require-approval [never|any|broadening]` | Approval level for IAM changes |
| `--outputs-file FILE` | Write stack outputs to JSON file |
| `--parameters KEY=VALUE` | Pass CloudFormation parameters |
| `--toolkit-stack-name NAME` | Custom bootstrap stack name |
| `--app COMMAND` | Override app command from `cdk.json` |
| `--context KEY=VALUE` | Add runtime context |
| `--verbose` | Verbose output |

## Common Imports

```typescript
import { App, Stack, StackProps, Duration, RemovalPolicy, CfnOutput } from "aws-cdk-lib";
import { Construct } from "constructs";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as lambdaNodejs from "aws-cdk-lib/aws-lambda-nodejs";
import * as apigateway from "aws-cdk-lib/aws-apigateway";
import * as apigatewayv2 from "aws-cdk-lib/aws-apigatewayv2";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as ecs from "aws-cdk-lib/aws-ecs";
import * as ecsPatterns from "aws-cdk-lib/aws-ecs-patterns";
import * as iam from "aws-cdk-lib/aws-iam";
import * as sqs from "aws-cdk-lib/aws-sqs";
import * as sns from "aws-cdk-lib/aws-sns";
import * as snsSub from "aws-cdk-lib/aws-sns-subscriptions";
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as origins from "aws-cdk-lib/aws-cloudfront-origins";
import * as events from "aws-cdk-lib/aws-events";
import * as targets from "aws-cdk-lib/aws-events-targets";
import * as kms from "aws-cdk-lib/aws-kms";
import * as secretsmanager from "aws-cdk-lib/aws-secretsmanager";
import * as ssm from "aws-cdk-lib/aws-ssm";
import * as route53 from "aws-cdk-lib/aws-route53";
import * as targetsR53 from "aws-cdk-lib/aws-route53-targets";
import * as certificatemanager from "aws-cdk-lib/aws-certificatemanager";
import { Template, Match } from "aws-cdk-lib/assertions";
import { AwsSolutionsChecks, NagSuppressions } from "cdk-nag";
```

## Quick Reference

### App Structure

```typescript
const app = new App();
new MyStack(app, "MyStack", {
  env: { account: "123456789012", region: "us-east-1" },
});
app.synth();
```

### Stack Structure

```typescript
class MyStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);
    // Define resources here
  }
}
```

### Custom Construct Structure

```typescript
interface MyConstructProps {
  // Define props
}

class MyConstruct extends Construct {
  // public readonly properties

  constructor(scope: Construct, id: string, props: MyConstructProps) {
    super(scope, id);
    // Define resources here
  }
}
```

### Grant Methods Quick Reference

```typescript
s3.Bucket:
  .grantRead(principal)        // s3:GetObject, s3:ListBucket
  .grantWrite(principal)       // s3:PutObject, s3:DeleteObject
  .grantReadWrite(principal)   // Both
  .grantPut(principal)         // s3:PutObject
  .grantPublicAccess()         // Public read (use sparingly)

dynamodb.Table:
  .grantReadData(principal)    // GetItem, Query, Scan, etc.
  .grantWriteData(principal)   // PutItem, UpdateItem, DeleteItem
  .grantReadWriteData(principal)
  .grantFullAccess(principal)

lambda.Function:
  .grantInvoke(principal)      // lambda:InvokeFunction

sqs.Queue:
  .grantSendMessages(principal)
  .grantConsumeMessages(principal)
  .grantPurge(principal)

sns.Topic:
  .grantPublish(principal)
```

### Duration Helpers

```typescript
Duration.seconds(30)
Duration.minutes(5)
Duration.hours(1)
Duration.days(7)
Duration.millis(500)
```

### Removal Policies

```typescript
RemovalPolicy.DESTROY     // Delete resource on stack deletion
RemovalPolicy.RETAIN      // Retain resource on stack deletion (default)
RemovalPolicy.SNAPSHOT    // Snapshot before deletion (RDS, EFS)
```

### Lambda Runtimes

```typescript
lambda.Runtime.NODEJS_20_X
lambda.Runtime.NODEJS_18_X
lambda.Runtime.PYTHON_3_12
lambda.Runtime.PYTHON_3_11
lambda.Runtime.JAVA_21
lambda.Runtime.JAVA_17
lambda.Runtime.DOTNET_8
lambda.Runtime.GO_1_X
lambda.Runtime.RUBY_3_2
lambda.Runtime.PROVIDED_AL2023
```

## Common Escape Hatches

When L2 constructs don't expose a property you need:

### Raw CloudFormation Property

```typescript
const bucket = new s3.Bucket(this, "MyBucket");
const cfnBucket = bucket.node.defaultChild as s3.CfnBucket;
cfnBucket.addPropertyOverride("ObjectLockEnabled", true);
```

### Raw CloudFormation Resource

```typescript
// When no L2 exists
new CfnResource(this, "MyCustomResource", {
  type: "AWS::Service::Resource",
  properties: { /* ... */ },
});
```

### Raw IAM Policy Statement

```typescript
fn.addToRolePolicy(new iam.PolicyStatement({
  actions: ["custom:Action"],
  resources: ["*"],
}));
```

## CDK Version Compatibility

```bash
# Check current version
cdk --version

# Upgrade CDK CLI
npm install -g aws-cdk@latest

# Upgrade library in project
npm install aws-cdk-lib@latest constructs@latest

# Check for breaking changes
npm diff aws-cdk-lib
```

## Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Resource X does not exist` | Bootstrap missing | `cdk bootstrap` |
| `Access denied` | IAM permissions insufficient | Check AWS CLI profile permissions |
| `Stack deployment timeout` | Resource taking too long | Increase CloudFormation timeout |
| `No Such Bucket` during synth | Bootstrap bucket missing | `cdk bootstrap` |
| `Context value not found` | Missing context in `cdk.json` | Add or run `cdk context --reset` |
| `Nested stack limit exceeded` | Too many nested stacks | Use `includeNestedStacks: false` or split stacks |

## Resources

- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [CDK CLI Reference](https://docs.aws.amazon.com/cdk/v2/guide/cli.html)
- [Construct Hub](https://constructs.dev/)
