# Testing

CDK tests verify that your infrastructure code produces the expected CloudFormation templates. They run at **synth time** — no AWS credentials needed.

## Test Setup

Install test dependencies:

```bash
npm install -D jest @types/jest ts-jest
```

`jest.config.js`:

```javascript
module.exports = {
  testEnvironment: "node",
  roots: ["<rootDir>/test"],
  testMatch: ["**/*.test.ts"],
  transform: {
    "^.+\\.tsx?$": "ts-jest",
  },
};
```

## Fine-Grained Assertions (Recommended)

Use `@aws-cdk/assertions` (built into `aws-cdk-lib`) for fine-grained assertions:

```typescript
import { Template } from "aws-cdk-lib/assertions";
import * as cdk from "aws-cdk-lib";
import * as s3 from "aws-cdk-lib/aws-s3";

test("S3 bucket has encryption enabled", () => {
  const app = new cdk.App();
  const stack = new cdk.Stack(app, "TestStack");

  new s3.Bucket(stack, "MyBucket", {
    encryption: s3.BucketEncryption.S3_MANAGED,
  });

  const template = Template.fromStack(stack);

  template.hasResourceProperties("AWS::S3::Bucket", {
    BucketEncryption: {
      ServerSideEncryptionConfiguration: [
        {
          ServerSideEncryptionByDefault: {
            SSEAlgorithm: "AES256",
          },
        },
      ],
    },
  });
});
```

## Count Assertions

Assert on the number of resources:

```typescript
// Exactly 1 bucket
template.resourceCountIs("AWS::S3::Bucket", 1);

// At least 1 Lambda (deprecated — use resourceCountIs instead)
template.findResources("AWS::Lambda::Function");
```

## Specific Value Assertions

```typescript
// Check a specific property value
template.hasResourceProperties("AWS::DynamoDB::Table", {
  BillingMode: "PAY_PER_REQUEST",
  KeySchema: [
    { AttributeName: "pk", KeyType: "HASH" },
  ],
});
```

## Snapshot Testing

Snapshot tests capture the full synthesized template:

```typescript
import { Match, Template } from "aws-cdk-lib/assertions";

test("stack matches snapshot", () => {
  const app = new cdk.App();
  const stack = new MyStack(app, "TestStack");

  const template = Template.fromStack(stack);
  expect(template.toJSON()).toMatchSnapshot();
});
```

Update snapshots:

```bash
npx jest --updateSnapshot
```

## Testing IAM Permissions

```typescript
test("Lambda has S3 read access", () => {
  const app = new cdk.App();
  const stack = new cdk.Stack(app, "TestStack");

  const bucket = new s3.Bucket(stack, "MyBucket");
  const fn = new lambda.Function(stack, "MyFunction", {
    runtime: lambda.Runtime.NODEJS_20_X,
    handler: "index.handler",
    code: lambda.Code.fromInline("exports.handler = async () => {}"),
  });
  bucket.grantRead(fn);

  const template = Template.fromStack(stack);

  template.hasResourceProperties("AWS::IAM::Policy", {
    PolicyDocument: {
      Statement: Match.arrayWith([
        Match.objectLike({
          Action: ["s3:GetObject*", "s3:GetBucket*", "s3:List*"],
          Effect: "Allow",
        }),
      ]),
    },
  });
});
```

## Testing with Context

Pass context values for environment-aware tests:

```typescript
const app = new cdk.App({
  context: { environment: "test" },
});
const stack = new MyStack(app, "TestStack", {
  env: { account: "123456789012", region: "us-east-1" },
});
```

## Test Patterns

### Stack Testing Template

```typescript
import { Template } from "aws-cdk-lib/assertions";
import * as cdk from "aws-cdk-lib";

function createTestStack(): cdk.Stack {
  const app = new cdk.App();
  return new cdk.Stack(app, "TestStack", {
    env: { account: "123456789012", region: "us-east-1" },
  });
}

function createTemplate(stack: cdk.Stack): Template {
  return Template.fromStack(stack);
}
```

### Testing Custom Constructs

```typescript
test("MyConstruct creates Lambda with correct runtime", () => {
  const stack = createTestStack();
  new MyConstruct(stack, "TestConstruct", {
    functionName: "test-fn",
  });

  const template = createTemplate(stack);
  template.hasResourceProperties("AWS::Lambda::Function", {
    Runtime: "nodejs20.x",
  });
});
```

## Testing Against Deployed Resources (Integ Tests)

For full end-to-end testing, use `aws-cdk-lib/integ-tests`:

```typescript
import { IntegTest } from "@aws-cdk/integ-tests-alpha";

const app = new cdk.App();
const stack = new MyStack(app, "IntegStack");

new IntegTest(app, "MyIntegTest", {
  testCases: [stack],
  regions: ["us-east-1"],
});
```

## Resources

- [CDK Assertions Documentation](https://docs.aws.amazon.com/cdk/v2/guide/testing.html)
- [CDK Integ Tests Alpha](https://docs.aws.amazon.com/cdk/api/v2/docs/integ-tests-alpha-readme.html)
