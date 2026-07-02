# IAM & Security

## How CDK Handles IAM

CDK automatically generates IAM policies based on resource usage. In most cases, you don't write raw IAM policies — CDK infers the minimum required permissions from method calls.

```typescript
const bucket = new s3.Bucket(this, "MyBucket");
const fn = new lambda.Function(this, "MyFunction", { /* ... */ });

// CDK automatically adds s3:GetObject, s3:PutObject, etc. to fn's role
bucket.grantReadWrite(fn);
```

## Grant Methods

Each resource exposes grant methods that auto-generate IAM policies:

| Method | Effect |
|--------|--------|
| `bucket.grantRead(principal)` | `s3:GetObject`, `s3:ListBucket` |
| `bucket.grantWrite(principal)` | `s3:PutObject`, `s3:DeleteObject` |
| `bucket.grantReadWrite(principal)` | Both read + write |
| `bucket.grantPut(principal)` | `s3:PutObject` |
| `table.grantReadData(principal)` | `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan` |
| `table.grantWriteData(principal)` | `dynamodb:PutItem`, `dynamodb:UpdateItem`, `dynamodb:DeleteItem` |
| `table.grantReadWriteData(principal)` | Both read + write |
| `queue.grantSendMessages(principal)` | `sqs:SendMessage` |
| `queue.grantConsumeMessages(principal)` | `sqs:ReceiveMessage`, `sqs:DeleteMessage` |
| `topic.grantPublish(principal)` | `sns:Publish` |
| `function.grantInvoke(principal)` | `lambda:InvokeFunction` |

## IAM Roles

### Creating a Role

```typescript
import * as iam from "aws-cdk-lib/aws-iam";

const role = new iam.Role(this, "MyRole", {
  assumedBy: new iam.ServicePrincipal("lambda.amazonaws.com"),
  description: "Custom role for Lambda execution",
  managedPolicies: [
    iam.ManagedPolicy.fromAwsManagedPolicyName("service-role/AWSLambdaBasicExecutionRole"),
  ],
});
```

### Inline Policies

```typescript
role.addToPolicy(new iam.PolicyStatement({
  actions: ["kms:Decrypt", "kms:Encrypt"],
  resources: [key.keyArn],
}));
```

### Custom Managed Policies

```typescript
const policy = new iam.ManagedPolicy(this, "MyPolicy", {
  statements: [
    new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ["ec2:DescribeInstances"],
      resources: ["*"],
    }),
  ],
});
role.addManagedPolicy(policy);
```

## Principle of Least Privilege

Always grant the minimum permissions needed:

```typescript
// ❌ Too broad
bucket.grantReadWrite(fn);

// ✅ Just what's needed
bucket.grantRead(fn);         // Only read access
```

## Cross-Stack Permissions

When resources are in different stacks:

```typescript
// stack-a.ts
const bucket = new s3.Bucket(this, "MyBucket");
// Export for cross-stack reference
(this.node.root as App).node.setContext("BucketArn", bucket.bucketArn);

// stack-b.ts
const fn = new lambda.Function(this, "MyFunction", { /* ... */ });
const bucket = s3.Bucket.fromBucketArn(this, "ImportedBucket",
  ssm.StringParameter.valueFromLookup(this, "/my-app/bucket-arn"));
bucket.grantRead(fn);
```

Better approach — pass constructs directly if stacks are in the same app:

```typescript
const app = new App();
const infra = new InfraStack(app, "InfraStack");
const appStack = new AppStack(app, "AppStack", { bucket: infra.bucket });
appStack.addDependency(infra);
```

## Security Best Practices

### Encryption at Rest

```typescript
// S3 SSE-S3
const bucket = new s3.Bucket(this, "MyBucket", {
  encryption: s3.BucketEncryption.S3_MANAGED,
});

// S3 SSE-KMS
const bucket = new s3.Bucket(this, "MyBucket", {
  encryption: s3.BucketEncryption.KMS,
  encryptionKey: new kms.Key(this, "MyKey"),
});

// DynamoDB encryption (default is AWS owned)
const table = new dynamodb.Table(this, "MyTable", {
  encryption: dynamodb.TableEncryption.AWS_MANAGED,
});
```

### Encryption in Transit

```typescript
// CloudFront forces HTTPS
const distribution = new cloudfront.Distribution(this, "Distribution", {
  defaultBehavior: {
    origin: new origins.S3Origin(bucket),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
  },
});

// ALB only accepts HTTPS
const listener = alb.addListener("Listener", {
  protocol: elbv2.ApplicationProtocol.HTTPS,
  certificates: [certificate],
});
```

### Secrets and Environment Variables

Never hardcode secrets:

```typescript
// ❌ Never
const fn = new lambda.Function(this, "Fn", {
  environment: {
    DB_PASSWORD: "hunter2",
  },
});

// ✅ Use Secrets Manager
const secret = secretsmanager.Secret.fromSecretNameV2(this, "DbSecret", "prod/db");
fn.addEnvironment("DB_PASSWORD", secret.secretValue.toString());

// ✅ Use SSM Parameter Store
const param = ssm.StringParameter.fromSecureStringParameterAttributes(
  this, "DbParam", { parameterName: "/prod/db/password" }
);
fn.addEnvironment("DB_PASSWORD", param.stringValue);
```

## Common IAM Patterns

| Pattern | Solution |
|---------|----------|
| Lambda reads from S3 | `bucket.grantRead(lambdaFn)` |
| Lambda writes to DynamoDB | `table.grantWriteData(lambdaFn)` |
| API Gateway invokes Lambda | Automatic with `LambdaIntegration` |
| Lambda sends to SQS | `queue.grantSendMessages(lambdaFn)` |
| Cross-account access | Use `iam.AccountPrincipal` in resource policy |
| Service-to-service | `role.addToPolicy(...)` |

## Resources

- [CDK IAM Module](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-iam-readme.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
