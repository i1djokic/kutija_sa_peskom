# Best Practices

## Project Structure

```
lib/
├── stacks/
│   ├── network-stack.ts        # VPC, subnets, NAT
│   ├── database-stack.ts       # RDS, DynamoDB, ElastiCache
│   ├── compute-stack.ts        # Lambda, ECS, EKS
│   └── api-stack.ts            # API Gateway, CloudFront
├── constructs/
│   ├── api-lambda.ts           # Reusable API Lambda pattern
│   ├── secure-bucket.ts        # Bucket with enforced encryption
│   └── scheduled-task.ts       # EventBridge + Lambda pattern
└── utils/
    ├── naming.ts               # Consistent resource naming
    └── constants.ts            # Environment configs
```

## Construct Design

### Favor Composition Over Inheritance

```typescript
// ✅ Composition
export class SecureBucket extends Construct {
  public readonly bucket: s3.Bucket;

  constructor(scope: Construct, id: string, props?: s3.BucketProps) {
    super(scope, id);
    this.bucket = new s3.Bucket(this, "InnerBucket", {
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      ...props,
    });
  }
}

// ❌ Inheritance (avoids auto-generated logical IDs)
export class SecureBucket extends s3.Bucket {
  // Not recommended
}
```

### Expose Meaningful Properties

```typescript
export class ApiLambda extends Construct {
  public readonly api: apigateway.LambdaRestApi;
  public readonly function: lambda.Function;

  constructor(scope: Construct, id: string, props: ApiLambdaProps) {
    super(scope, id);
    // ...
  }
}
```

## Stack Organization

### One Concern Per Stack

```typescript
// ✅ Split by concern
new NetworkStack(app, "NetworkStack", { env });
new DatabaseStack(app, "DatabaseStack", { env });
new ComputeStack(app, "ComputeStack", { env });

// ❌ Single monolithic stack
new MonolithStack(app, "MonolithStack", { env });
```

### Use StackProps for Configuration

```typescript
export interface MyStackProps extends StackProps {
  vpc: ec2.IVpc;
  database: dynamodb.ITable;
  stageName: string;
}
```

## Configuration Management

### Use Context, Not Hardcoded Values

```json
// cdk.json
{
  "context": {
    "dev": {
      "instanceType": "t3.small",
      "minCapacity": 1
    },
    "prod": {
      "instanceType": "t3.large",
      "minCapacity": 3
    }
  }
}
```

```typescript
// Access context
const stage = scope.node.tryGetContext("stage") as string;
const config = scope.node.tryGetContext(stage);
```

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| Construct ID | PascalCase | `MyBucket`, `ApiLambda` |
| Stack name | PascalCase + `Stack` suffix | `NetworkStack`, `ApiStack` |
| Logical ID | Auto-generated (do not override) | — |
| Physical name | Let CDK auto-generate (or use `cdk-nag`) | — |
| Export names | `${stackName}-ResourceName` | `NetworkStack-VpcId` |

## Removal Policies

```typescript
// Development stacks — allow cleanup
removalPolicy: RemovalPolicy.DESTROY,
autoDeleteObjects: true,

// Production stacks — protect data
removalPolicy: RemovalPolicy.RETAIN,
// No autoDeleteObjects
```

## Tagging

Apply tags for cost tracking and resource management:

```typescript
import { Tags } from "aws-cdk-lib";

Tags.of(app).add("Environment", "production");
Tags.of(app).add("Project", "my-app");
Tags.of(app).add("CostCenter", "12345");

// Override at stack level
Tags.of(stack).add("Environment", "dev");
```

## Security

| Rule | Rationale |
|------|-----------|
| Use `grant*` methods instead of raw IAM policies | Auto-generates least-privilege policies |
| Enable S3 encryption by default | Data protection at rest |
| Enable DynamoDB encryption | Data protection at rest |
| Use `secretsmanager.Secret` instead of env vars | Secrets are encrypted and auditable |
| Set `removalPolicy: RETAIN` in production | Prevents accidental data loss |
| Avoid hardcoded account/region | Use `CDK_DEFAULT_ACCOUNT` and `CDK_DEFAULT_REGION` |

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Monolithic stack | Slow deploy, hard to reason about | Split by concern |
| Overriding logical IDs | Breaks CloudFormation updates | Let CDK auto-generate |
| Hardcoding ARNs | Fragile, not portable | Use `from{Resource}Arn()` methods |
| Using `Fn::Ref` directly | Bypasses CDK's type safety | Use L2 construct properties |
| Ignoring `cdk diff` | Surprises on deploy | Always run `cdk diff` before deploy |
| Manual resource naming | Name collisions, limits | Let CDK auto-generate names |

## CDK Nag (Security Linting)

```bash
npm install -D cdk-nag
```

```typescript
import { AwsSolutionsChecks, NagSuppressions } from "cdk-nag";

// Apply to entire app
NagSuppressions.addStackSuppressions(stack, [
  { id: "AwsSolutions-S1", reason: "Access logs not required for dev" },
]);
```

## Resources

- [CDK Best Practices](https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html)
- [cdk-nag](https://github.com/cdklabs/cdk-nag)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
