# Project Setup

## Prerequisites

```bash
node >= 18.x
npm >= 9.x
aws-cdk >= 2.0
```

Install the CDK CLI globally:

```bash
npm install -g aws-cdk
```

Verify installation:

```bash
cdk --version
```

## Creating a New Project

```bash
mkdir my-cdk-app && cd my-cdk-app
cdk init app --language typescript
```

This scaffolds:

```
my-cdk-app/
├── bin/
│   └── my-cdk-app.ts          # App entry point
├── lib/
│   └── my-cdk-app-stack.ts    # Main stack definition
├── test/
│   └── my-cdk-app.test.ts     # Unit tests
├── cdk.json                   # CDK configuration
├── tsconfig.json              # TypeScript config
├── package.json               # Dependencies
└── .gitignore
```

## Project Structure Guidelines

| Path | Purpose |
|------|---------|
| `bin/` | App entry points (one per app) |
| `lib/` | Stack and construct definitions |
| `lib/constructs/` | Reusable construct components |
| `lib/stacks/` | Stack definitions |
| `lib/utils/` | Helper functions, constants |
| `test/` | Unit and integration tests |
| `cdk.json` | CDK context and configuration |

## Configuring TypeScript

`tsconfig.json` should target modern JS:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2020"],
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist"
  },
  "exclude": ["node_modules", "cdk.out", "dist"]
}
```

## CDK Configuration (`cdk.json`)

```json
{
  "app": "npx ts-node --prefer-ts-exts bin/my-cdk-app.ts",
  "context": {
    "@aws-cdk/aws-lambda:recognizeLayerVersion": true,
    "@aws-cdk/core:checkSecretUsage": true,
    "@aws-cdk/core:target-partitions": ["aws", "aws-cn"],
    "environments": {
      "dev": { "account": "111111111111", "region": "us-east-1" },
      "prod": { "account": "222222222222", "region": "eu-west-1" }
    }
  }
}
```

## Dependencies

Core packages for CDK v2:

```bash
npm install aws-cdk-lib constructs
npm install -D @types/node ts-node typescript jest @types/jest ts-jest
```

## Bootstrapping

Before first deployment, bootstrap the target environment:

```bash
cdk bootstrap aws://ACCOUNT-ID/REGION
```

This creates an S3 bucket and IAM roles that CDK needs for deployment.

## Common Setup Issues

| Issue | Solution |
|-------|----------|
| `cdk` command not found | Reinstall: `npm install -g aws-cdk` |
| TypeScript compilation errors | Check `tsconfig.json` target and module settings |
| `--profile` not working | Use `AWS_PROFILE=xxx cdk deploy` |
| Bootstrap fails | Ensure `AdministratorAccess` policy is attached to the caller |

## Resources

- [CDK Workshop](https://cdkworkshop.com/)
- [CDK Init Templates](https://docs.aws.amazon.com/cdk/v2/guide/hello_world.html)
