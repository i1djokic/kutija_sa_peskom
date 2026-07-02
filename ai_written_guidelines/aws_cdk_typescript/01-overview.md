# AWS CDK Overview & Architecture

## What is AWS CDK?

The **AWS Cloud Development Kit (CDK)** is an infrastructure-as-code (IaC) framework that lets you define AWS cloud resources using familiar programming languages (TypeScript, Python, Java, C#, Go) instead of YAML or JSON templates.

Your CDK code is **synthesized** into CloudFormation templates, which are then deployed by CloudFormation.

## How It Works

```text
CDK App (TypeScript)
    │
    ├── synthesize ──► CloudFormation template (JSON/YAML)
    │                        │
    └── deploy ──────────────► CloudFormation stack
                                     │
                                     └── creates/modifies AWS resources
```

Three main stages:
1. **Author** — define infrastructure in TypeScript
2. **Synthesize** (`cdk synth`) — generates CloudFormation templates
3. **Deploy** (`cdk deploy`) — executes via CloudFormation

## Key Benefits

| Benefit | Description |
|---------|-------------|
| **Type safety** | TypeScript compilation catches errors early |
| **Reusable components** | Constructs encapsulate best practices |
| **High-level abstractions** | Less boilerplate than raw CloudFormation |
| **Logic & loops** | Use TypeScript conditionals, loops, functions |
| **Granular permissions** | IAM policies auto-generated from usage |

## CDK Toolkit (CLI)

The CLI (`cdk`) is the primary interface:

```bash
cdk init          # Scaffold a new project
cdk synth         # Generate CloudFormation templates
cdk deploy        # Deploy stack to AWS
cdk diff          # Compare deployed stack with local
cdk destroy       # Tear down stack
cdk list          # List stacks in the app
cdk bootstrap     # Prepare environment for CDK deployments
```

## Version Support

| CDK Version | Status | TypeScript Support |
|-------------|--------|--------------------|
| v1 | Maintenance | >= 3.8 |
| v2 (current) | Active | >= 3.8 |
| v2 + aws-lambda-python-alpha | Experimental | >= 4.0 |

Always use **CDK v2** for new projects — it includes all AWS constructs in a single package (`aws-cdk-lib`).

## Resources

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/v2/guide/home.html)
- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [AWS CDK GitHub](https://github.com/aws/aws-cdk)
