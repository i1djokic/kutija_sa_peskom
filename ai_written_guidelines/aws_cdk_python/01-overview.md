# AWS CDK Overview & Architecture

## What is AWS CDK?

The **AWS Cloud Development Kit (CDK)** is an infrastructure-as-code (IaC) framework that lets you define AWS cloud resources using familiar programming languages (Python, TypeScript, Java, C#, Go) instead of YAML or JSON templates.

Your CDK code is **synthesized** into CloudFormation templates, which are then deployed by CloudFormation.

## How It Works

```text
CDK App (Python)
    │
    ├── synthesize ──► CloudFormation template (JSON/YAML)
    │                        │
    └── deploy ──────────────► CloudFormation stack
                                     │
                                     └── creates/modifies AWS resources
```

Three main stages:
1. **Author** — define infrastructure in Python
2. **Synthesize** (`cdk synth`) — generates CloudFormation templates
3. **Deploy** (`cdk deploy`) — executes via CloudFormation

## Key Benefits

| Benefit | Description |
|---------|-------------|
| **Readable syntax** | Python's clarity reduces boilerplate versus YAML |
| **Reusable components** | Constructs encapsulate best practices |
| **High-level abstractions** | Less boilerplate than raw CloudFormation |
| **Logic & loops** | Use Python conditionals, loops, comprehensions |
| **Granular permissions** | IAM policies auto-generated from usage |
| **Rich ecosystem** | Use any Python package (boto3, pytest, mypy) |

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

| CDK Version | Status | Python Support |
|-------------|--------|----------------|
| v1 | Maintenance | >= 3.6 |
| v2 (current) | Active | >= 3.7 |
| v2 (latest) | Active | >= 3.8 |

Always use **CDK v2** for new projects — it includes all AWS constructs in a single package (`aws-cdk-lib`).

## Python-Specific Advantages

- **Duck typing** — construct props are plain dictionaries, easy to inspect
- **REPL-friendly** — test imports and APIs in a Python shell
- **Mypy compatible** — type hints catch errors at lint time
- **Pytest integration** — mature test framework with fixtures

## Resources

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/v2/guide/home.html)
- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
- [AWS CDK GitHub](https://github.com/aws/aws-cdk)
