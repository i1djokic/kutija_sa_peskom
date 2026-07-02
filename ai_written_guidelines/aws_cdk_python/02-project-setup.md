# Project Setup

## Prerequisites

```bash
python >= 3.8
pip >= 21
nodejs >= 18.x   # CDK CLI requires Node.js (even for Python projects)
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
cdk init app --language python
```

This scaffolds:

```
my-cdk-app/
├── app.py                          # App entry point
├── my_cdk_app/
│   ├── __init__.py
│   └── my_cdk_app_stack.py         # Main stack definition
├── tests/
│   ├── __init__.py
│   └── unit/
│       ├── __init__.py
│       └── test_my_cdk_app_stack.py
├── cdk.json                        # CDK configuration
├── requirements-dev.txt            # Dev dependencies
├── requirements.txt                # Runtime dependencies
├── setup.py                        # Package setup
├── source.bat                      # Windows venv activation
└── .venv/                          # Virtual environment
```

## Project Structure Guidelines

| Path | Purpose |
|------|---------|
| `app.py` | App entry point (one per project) |
| `my_cdk_app/` | Stack and construct definitions |
| `my_cdk_app/constructs/` | Reusable construct components |
| `my_cdk_app/stacks/` | Stack definitions |
| `my_cdk_app/utils/` | Helper functions, constants |
| `tests/` | Unit and integration tests |
| `cdk.json` | CDK context and configuration |

## Virtual Environment Setup

After `cdk init`, activate the venv and install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate     # Linux/macOS
# .venv\Scripts\activate.bat  # Windows

pip install -r requirements.txt
pip install -r requirements-dev.txt
```

## Dependencies

`requirements.txt` — core dependencies:

```text
aws-cdk-lib>=2.0,<3.0
constructs>=10.0,<11.0
```

`requirements-dev.txt` — development dependencies:

```text
pytest>=7.0
pytest-cov>=4.0
mypy>=1.0
black>=23.0
ruff>=0.1
```

## CDK Configuration (`cdk.json`)

```json
{
  "app": "python app.py",
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

## Bootstrapping

Before first deployment, bootstrap the target environment:

```bash
cdk bootstrap aws://ACCOUNT-ID/REGION
```

## Type Checking with Mypy

Configure `mypy.ini`:

```ini
[mypy]
python_version = 3.11
strict = true
ignore_missing_imports = true
```

Run type checks:

```bash
mypy app.py my_cdk_app/
```

## Code Formatting

```bash
# Format code
black my_cdk_app/ tests/

# Lint
ruff check my_cdk_app/ tests/
```

## Common Setup Issues

| Issue | Solution |
|-------|----------|
| `cdk` command not found | Reinstall: `npm install -g aws-cdk` |
| ModuleNotFoundError | Activate venv: `source .venv/bin/activate` |
| `--profile` not working | Use `AWS_PROFILE=xxx cdk deploy` |
| Bootstrap fails | Ensure `AdministratorAccess` policy is on the caller |
| Mypy errors on CDK types | Add `ignore_missing_imports = true` to mypy.ini |

## Resources

- [CDK Workshop (Python)](https://cdkworkshop.com/30-python.html)
- [CDK Init Templates](https://docs.aws.amazon.com/cdk/v2/guide/hello_world.html)
