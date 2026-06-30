# CloudFormation — DevOps Cheatsheet

## Template Structure

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: ...

Parameters:
  Env:
    Type: String
    Default: dev
    AllowedValues: [dev, prod]

Mappings:
  RegionMap:
    us-east-1:
      Ami: ami-123

Conditions:
  IsProd: !Equals [!Ref Env, prod]

Resources:
  Bucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    Properties:
      BucketName: !Sub "${Env}-my-bucket"
      VersioningConfiguration:
        Status: Enabled
    DependsOn: SomeOtherResource

Outputs:
  BucketName:
    Value: !Ref Bucket
    Export:
      Name: !Sub "${AWS::StackName}-BucketName"
```

## Intrinsic Functions

| Function | Use |
|----------|-----|
| `!Ref LogicalId` | reference resource / parameter |
| `!GetAtt Resource.Attribute` | get resource attribute |
| `!Sub "text ${Var}"` | string substitution |
| `!Join [",", [a, b]]` | join list |
| `!Select [0, ["a","b"]]` | pick from list |
| `!FindInMap [Map, Key, Val]` | lookup in mapping |
| `!Equals [a, b]` | condition |
| `!If [cond, true, false]` | conditional value |
| `!ImportValue ExportedName` | cross-stack reference |
| `!Base64 value` | base64 encode |

## Pseudo Parameters

| Var | Value |
|-----|-------|
| `AWS::AccountId` | account ID |
| `AWS::Region` | current region |
| `AWS::StackName` | stack name |
| `AWS::StackId` | stack ID |
| `AWS::NoValue` | remove property if condition false |

## Policies

```yaml
# Deletion
DeletionPolicy: Retain | Delete | Snapshot

# Update
UpdateReplacePolicy: Retain | Delete | Snapshot
```

## CreationPolicy / WaitCondition

```yaml
CreationPolicy:
  ResourceSignal:
    Timeout: PT15M
    Count: 1
```

## CloudFormation Init (cfn-init)

```yaml
Metadata:
  AWS::CloudFormation::Init:
    config:
      packages:
        yum:
          httpd: []
      files:
        /var/www/index.html:
          content: !Sub "Hello from ${Env}"
      commands:
        01_enable:
          command: systemctl enable httpd
      services:
        sysvinit:
          httpd:
            enabled: true
            ensureRunning: true
```

## Common Commands

```bash
# Create / Update
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name my-stack \
  --parameter-overrides Env=prod \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Project=myapp

# Delete
aws cloudformation delete-stack --stack-name my-stack

# Validate
aws cloudformation validate-template \
  --template-body file://template.yaml

# List / Describe
aws cloudformation list-stacks
aws cloudformation describe-stacks --stack-name my-stack
aws cloudformation describe-stack-events --stack-name my-stack

# Outputs
aws cloudformation describe-stacks \
  --query "Stacks[0].Outputs" \
  --stack-name my-stack

# Change set (review before update)
aws cloudformation create-change-set \
  --stack-name my-stack \
  --template-body file://template.yaml \
  --change-set-name my-change
aws cloudformation execute-change-set \
  --change-set-name my-change \
  --stack-name my-stack

# Drift detection
aws cloudformation detect-stack-drift \
  --stack-name my-stack
aws cloudformation describe-stack-resource-drifts \
  --stack-name my-stack
```

## Nested Stacks

```yaml
Resources:
  Nested:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: https://s3.amazonaws.com/bucket/nested.yaml
      Parameters:
        Env: !Ref Env
```

## Best Practices

- Use parameters for configurable values, not hardcoded
- Export outputs with `!Sub "${AWS::StackName}-X"` to avoid name clashes
- Use `AWS::NoValue` with `!If` to conditionally omit properties
- Prefer YAML over JSON
- Use `cfn-lint` and `cfn-nag` for validation
- Pin template URLs for nested stacks to versioned paths (e.g. S3 with version or commit hash)
- Never hardcode secrets — use Secrets Manager / SSM Parameter Store
- Use `DeletionPolicy: Retain` on databases, S3 buckets with data
