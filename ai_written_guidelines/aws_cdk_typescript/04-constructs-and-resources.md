# Constructs & Resources

## Naming Convention

Import AWS service modules with namespace aliases:

```typescript
import * as s3 from "aws-cdk-lib/aws-s3";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as apigateway from "aws-cdk-lib/aws-apigateway";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as iam from "aws-cdk-lib/aws-iam";
import * as sqs from "aws-cdk-lib/aws-sqs";
import * as sns from "aws-cdk-lib/aws-sns";
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as route53 from "aws-cdk-lib/aws-route53";
```

## S3 Bucket

```typescript
import * as s3 from "aws-cdk-lib/aws-s3";
import { RemovalPolicy } from "aws-cdk-lib";

const bucket = new s3.Bucket(this, "MyBucket", {
  versioned: true,
  removalPolicy: RemovalPolicy.DESTROY,      // For dev only
  autoDeleteObjects: true,                    // Clean up on destroy
  encryption: s3.BucketEncryption.S3_MANAGED,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  lifecycleRules: [
    { expiration: Duration.days(90) },
  ],
});
```

## Lambda Function

```typescript
import * as lambda from "aws-cdk-lib/aws-lambda";
import { Duration } from "aws-cdk-lib";

const fn = new lambda.Function(this, "MyFunction", {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: "index.handler",
  code: lambda.Code.fromAsset("dist/lambda"),
  memorySize: 256,
  timeout: Duration.seconds(30),
  environment: {
    TABLE_NAME: table.tableName,
  },
  tracing: lambda.Tracing.ACTIVE,
});
```

### Lambda with Docker (custom runtime)

```typescript
new lambda.DockerImageFunction(this, "MyDockerFunction", {
  code: lambda.DockerImageCode.fromImageAsset("src/docker-fn"),
  memorySize: 1024,
  timeout: Duration.minutes(5),
});
```

## API Gateway (REST)

```typescript
import * as apigateway from "aws-cdk-lib/aws-apigateway";

const api = new apigateway.LambdaRestApi(this, "MyApi", {
  handler: fn,
  proxy: false,
});

const items = api.root.addResource("items");
items.addMethod("GET", new apigateway.LambdaIntegration(fn));
items.addMethod("POST", new apigateway.LambdaIntegration(fn));

const item = items.addResource("{id}");
item.addMethod("GET", new apigateway.LambdaIntegration(fn));
item.addMethod("DELETE", new apigateway.LambdaIntegration(fn));
```

### API Gateway (HTTP)

```typescript
import * as apigatewayv2 from "aws-cdk-lib/aws-apigatewayv2";
import { HttpLambdaIntegration } from "aws-cdk-lib/aws-apigatewayv2-integrations";

const httpApi = new apigatewayv2.HttpApi(this, "MyHttpApi");
httpApi.addRoutes({
  path: "/items",
  methods: [apigatewayv2.HttpMethod.GET],
  integration: new HttpLambdaIntegration("ItemsIntegration", fn),
});
```

## DynamoDB Table

```typescript
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import { RemovalPolicy } from "aws-cdk-lib";

const table = new dynamodb.Table(this, "MyTable", {
  partitionKey: { name: "pk", type: dynamodb.AttributeType.STRING },
  sortKey: { name: "sk", type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
  removalPolicy: RemovalPolicy.DESTROY,
  timeToLiveAttribute: "ttl",
  pointInTimeRecovery: true,
});
```

## VPC & Networking

```typescript
import * as ec2 from "aws-cdk-lib/aws-ec2";

const vpc = new ec2.Vpc(this, "MyVpc", {
  maxAzs: 2,
  natGateways: 1,
  subnetConfiguration: [
    {
      cidrMask: 24,
      name: "public",
      subnetType: ec2.SubnetType.PUBLIC,
    },
    {
      cidrMask: 24,
      name: "private",
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
    },
  ],
});
```

## SQS Queue

```typescript
import * as sqs from "aws-cdk-lib/aws-sqs";
import { Duration } from "aws-cdk-lib";

const queue = new sqs.Queue(this, "MyQueue", {
  visibilityTimeout: Duration.seconds(30),
  retentionPeriod: Duration.days(4),
  encryption: sqs.QueueEncryption.SQS_MANAGED,
});
```

## SNS Topic

```typescript
import * as sns from "aws-cdk-lib/aws-sns";
import * as subscriptions from "aws-cdk-lib/aws-sns-subscriptions";

const topic = new sns.Topic(this, "MyTopic");
topic.addSubscription(new subscriptions.EmailSubscription("user@example.com"));
```

## CloudFront Distribution

```typescript
import * as cloudfront from "aws-cdk-lib/aws-cloudfront";
import * as origins from "aws-cdk-lib/aws-cloudfront-origins";

const distribution = new cloudfront.Distribution(this, "MyDistribution", {
  defaultBehavior: {
    origin: new origins.S3Origin(bucket),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
  },
  priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
});
```

## EventBridge Rule

```typescript
import * as events from "aws-cdk-lib/aws-events";
import * as targets from "aws-cdk-lib/aws-events-targets";

const rule = new events.Rule(this, "ScheduleRule", {
  schedule: events.Schedule.rate(Duration.hours(1)),
});
rule.addTarget(new targets.LambdaFunction(fn));
```

## L3 Patterns (Multi-Resource)

```typescript
import { LambdaRestApi } from "aws-cdk-lib/aws-apigateway";
import { ApplicationLoadBalancedFargateService } from "aws-cdk-lib/aws-ecs-patterns";

// API Gateway + Lambda
new LambdaRestApi(this, "Api", { handler: fn });

// ECS Fargate + ALB
new ApplicationLoadBalancedFargateService(this, "Service", {
  taskImageOptions: { image: ecs.ContainerImage.fromAsset("src/app") },
});
```

## CloudFormation Outputs

Export values for cross-stack or cross-environment reference:

```typescript
import { CfnOutput } from "aws-cdk-lib";

new CfnOutput(this, "BucketName", {
  value: bucket.bucketName,
  description: "S3 bucket name",
  exportName: `${this.stackName}-BucketName`,
});
```

## Resource

- [CDK Construct Library](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [Construct Hub](https://constructs.dev/)
