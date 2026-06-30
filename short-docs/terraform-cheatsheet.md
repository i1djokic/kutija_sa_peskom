# Terraform — DevOps Cheatsheet

## HCL Basics

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "my-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  name = "${var.env}-${var.app}"
}

resource "aws_s3_bucket" "this" {
  bucket = local.name
  tags   = var.tags
}

data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}
```

## Resource Meta-Arguments

```hcl
depends_on = [aws_instance.other]
count      = 3
for_each   = toset(var.items)
provider   = aws.west

lifecycle {
  create_before_destroy = true
  prevent_destroy       = true
  ignore_changes        = [tags]
}
```

## Functions

```hcl
# String
format("%s-%s", var.a, var.b)
join(",", ["a", "b"])
split(",", "a,b")
replace(s, "old", "new")
lower(s), upper(s), title(s)
trimspace(s)

# Collection
length(list)
element(list, 0)
slice(list, 0, 2)
concat(list1, list2)
flatten([[1], [2]])
distinct([1, 1, 2])
lookup(map, "key", "default")
merge(map1, map2)
keys(map), values(map)

# Numeric
max(1, 2), min(1, 2)
ceil(1.1), floor(1.9)
tobool, tostring, tonumber

# Encoding
base64encode(s)
base64decode(s)
jsonencode(obj)
jsondecode(s)

# Filesystem
file("path")
templatefile("path.tftpl", { var = val })

# IP
cidrsubnet("10.0.0.0/16", 8, 1)   # 10.0.1.0/24
cidrhost("10.0.1.0/24", 10)        # 10.0.1.10
cidrnetmask("10.0.1.0/24")         # 255.255.255.0
```

## Conditionals & Loops

```hcl
# Ternary
name = var.env == "prod" ? "myapp-prod" : "myapp-dev"

# for (list)
names = [for o in var.objects : o.name]
# for (map)
names = {for k, v in var.map : k => upper(v)}

# for with if
names = [for o in var.objects : o.name if o.enabled]

# splat
arns = aws_s3_bucket.this[*].arn
```

## Modules

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.name
  cidr = "10.0.0.0/16"
}

# Local module
module "my_module" {
  source = "./modules/my_module"
}
```

## Data Sources

```hcl
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db"
}
```

## Workspaces

```bash
terraform workspace new dev
terraform workspace select prod
terraform workspace list
terraform workspace show
```

```hcl
terraform {
  backend "s3" {
    key = "env:/${terraform.workspace}/terraform.tfstate"
  }
}
```

## State Management

```bash
terraform state list
terraform state show aws_s3_bucket.this
terraform state mv aws_s3_bucket.old aws_s3_bucket.new
terraform state rm aws_s3_bucket.this
terraform state pull > backup.tfstate
terraform state push backup.tfstate
terraform import aws_s3_bucket.this my-existing-bucket
```

## Commands

```bash
# Init / Validate
terraform init -upgrade
terraform init -reconfigure
terraform validate
terraform fmt -recursive

# Plan / Apply
terraform plan -out plan.tfplan
terraform plan -var-file=prod.tfvars
terraform apply plan.tfplan
terraform apply -auto-approve
terraform destroy -target=aws_s3_bucket.this

# Console
terraform console
> cidrsubnet("10.0.0.0/16", 8, 1)
> {for k, v in var.tags : k => upper(v)}

# Taint / Untaint (deprecated, use -replace)
terraform taint resource
terraform untaint resource
terraform apply -replace="aws_instance.this"

# Graph
terraform graph | dot -Tpng > graph.png
```

## Sensitive & Import

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

```bash
terraform import module.db.aws_db_instance.this db-12345
```

## Best Practices

- Use remote state (S3 + DynamoDB locking)
- Pin provider and module versions
- Use workspaces or directories per environment (not branches)
- Never hardcode secrets — use `sensitive` vars or Secrets Manager
- Use `prevent_destroy` on critical resources (DBs, buckets with data)
- Validate with `terraform validate` + `tflint` + `checkov` / `tfsec`
- Format with `terraform fmt`
- Structure: `envs/` (per env) + `modules/` (reusable) + `_global/`
- Use `locals` to reduce repetition
- Prefer `for_each` over `count` when keys matter
- Write explicit `depends_on` only when necessary (otherwise let auto-dependency work)
