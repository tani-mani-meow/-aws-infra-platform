# AWS Infrastructure Platform

**Multi-tier AWS infrastructure built with Terraform.**

Modular networking, compute, database, IAM, and bastion layers — isolated across dev, staging, and prod environments.

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![IaC](https://img.shields.io/badge/IaC-100%25-success)]()

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Modules](#modules)
- [Quick Start](#quick-start)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security](#security)
- [Project Structure](#project-structure)
- [License](#license)

---

## Overview

This project provisions a full AWS environment from scratch — VPC, subnets, bastion host, app servers, managed database, IAM, the works. Everything is Terraform. No console clicking.

What gets built:

- **Custom VPC** with multi-AZ public/private subnet topology
- **Bastion host** for SSH access to private resources
- **EC2 app servers** in private subnets with templatized userdata
- **RDS MySQL** with Multi-AZ failover, encryption, and automated backups
- **IAM users, groups, and policies** scoped with least-privilege
- **Layered security groups** — each tier only talks to the one above it

### Why I built it this way

| Decision | Why |
|----------|----|
| Custom VPC over default | Full control over CIDRs, subnets, and route tables |
| RDS over MySQL-on-EC2 | Managed failover, backups, and patching out of the box |
| Bastion host over SSM | Demonstrates VPC routing and SG chaining fundamentals; SSM is the upgrade path |
| `cidrsubnet()` over hardcoded CIDRs | Scales dynamically with AZ count — no manual math |
| Single vs per-AZ NAT | One NAT in dev saves ~$64/mo; per-AZ in prod for HA |
| `for_each` over `count` | Stable resource addressing — removing a user doesn't shift indices |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AWS Account                                   │
│                                                                         │
│  ┌──── VPC (10.0.0.0/16 dev │ 10.1.0.0/16 staging │ 172.16.0.0/16 prod)│
│  │                                                                      │
│  │  ┌──── Public Subnets (Multi-AZ) ─────────────────────────────────┐ │
│  │  │                                                                 │ │
│  │  │   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │ │
│  │  │   │   Bastion    │    │     NAT      │    │     NAT      │     │ │
│  │  │   │    Host      │    │   Gateway    │    │   Gateway    │     │ │
│  │  │   │  (SSH Jump)  │    │   (AZ-1)     │    │   (AZ-2)*    │     │ │
│  │  │   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │ │
│  │  └──────────┼───────────────────┼───────────────────┼─────────────┘ │
│  │             │                   │                   │               │
│  │  ┌──── Private Subnets (Multi-AZ) ────────────────────────────────┐ │
│  │  │          ▼                   ▼                   ▼              │ │
│  │  │   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │ │
│  │  │   │     EC2      │    │     EC2      │    │    RDS       │     │ │
│  │  │   │   App Srv    │    │   App Srv    │    │   MySQL      │     │ │
│  │  │   │   (AZ-1)     │    │   (AZ-2)*    │    │  Multi-AZ    │     │ │
│  │  │   └──────────────┘    └──────────────┘    └──────────────┘     │ │
│  │  └────────────────────────────────────────────────────────────────┘ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌── IAM ──────────────────────────────────────────────────────────────┐│
│  │  3 Users → 1 Group (S3 Read) + 1 Independent (EC2 Read)            ││
│  └─────────────────────────────────────────────────────────────────────┘│
│                                         * prod only (2 instances, 3 AZs)│
└─────────────────────────────────────────────────────────────────────────┘
```

### Security group chain

```
Internet → [Bastion SG: SSH from admin CIDR] → Bastion Host
                                                     │
              [App SG: SSH from Bastion SG only] ◄───┘
                           │
              [DB SG: 3306 from App SG + Bastion SG] ◄── RDS MySQL
```

---

## Modules

Six Terraform modules, each with its own `variables.tf` and `outputs.tf`:

| Module | What it does | Notes |
|--------|-------------|-------|
| `networking` | VPC, subnets, IGW, NAT, routes | Uses `cidrsubnet()` for dynamic CIDRs, configurable single/per-AZ NAT |
| `security` | Security groups (bastion, app, db) | Layered rules — each tier scoped to the one above |
| `bastion` | Jump host in public subnet | IMDSv2 enforced, encrypted EBS, latest AMI lookup |
| `compute` | EC2 app servers | Templatized userdata, spread across AZs |
| `database` | RDS MySQL | Multi-AZ option, encryption, automated backups, custom parameter group |
| `iam` | Users, groups, policies | `for_each` over users, group membership, scoped policies |

### How modules depend on each other

```
environments/{dev,staging,prod}
    │
    ├── networking ──────────────────────────┐
    │       │                                │
    │       ├── security (needs vpc_id) ◄────┤
    │       │       │                        │
    │       │       ├── bastion (needs SG + subnet)
    │       │       ├── compute (needs SG + subnets)
    │       │       └── database (needs SG + subnets)
    │       │
    └── iam (independent — no VPC dependency)
```

---

## Quick Start

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- An EC2 key pair in your target region

### 1. Clone & configure

```bash
git clone https://github.com/tani-mani-meow/aws-infra-platform.git
cd aws-infra-platform

# Copy and edit the example variables file
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Edit terraform.tfvars with your values (key_name, db_password, admin IP, etc.)
```

### 2. Bootstrap remote state (one-time)

```bash
chmod +x scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh us-east-1 aws-infra-platform
```

### 3. Deploy

```bash
cd environments/dev
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Verify

```bash
# View all outputs
terraform output

# Get bastion SSH command
terraform output bastion_ssh_command

# Get RDS endpoint
terraform output db_endpoint

# View IAM credentials (sensitive)
terraform output -json iam_user_credentials
```

### 5. Cleanup

```bash
terraform destroy
```

---

## CI/CD Pipeline

Runs on **GitHub Actions** (`.github/workflows/terraform.yml`):

```
Pull Request                          Merge to main
    │                                      │
    ├── terraform fmt -check               ├── terraform fmt -check
    ├── terraform validate (all envs)      ├── terraform validate (all envs)
    ├── terraform plan (dev)               └── terraform apply (dev, auto)
    └── Plan commented on PR
```

- **OIDC auth** — no long-lived AWS keys stored in secrets
- **Matrix strategy** — validates all environments in parallel
- **Plan-on-PR** — reviewers see the exact diff before merge

---

## Security

| Practice | How it's implemented |
|----------|---------------------|
| No hardcoded credentials | Variables marked `sensitive`, `.tfvars` in `.gitignore` |
| Bastion-only SSH | App/DB servers can't be reached directly from the internet |
| Scoped security groups | Each tier only accepts traffic from the tier above |
| IMDSv2 enforced | `http_tokens = "required"` on all EC2 instances |
| Encrypted storage | EBS volumes and RDS storage encrypted at rest |
| Remote state encryption | S3 bucket with AES-256, versioning, public access blocked |
| State locking | DynamoDB prevents concurrent `terraform apply` runs |
| Scoped IAM policies | S3 read limited to project prefix, EC2 read-only (no `ec2:*`) |

More detail in [SECURITY.md](docs/SECURITY.md).

---



## Project Structure

```
aws-infra-platform/
├── .github/workflows/
│   └── terraform.yml              # CI/CD pipeline
├── modules/
│   ├── networking/                 # VPC, subnets, IGW, NAT, routes
│   ├── security/                   # Security groups (bastion, app, db)
│   ├── bastion/                    # Hardened jump host
│   ├── compute/                    # EC2 app servers + userdata template
│   ├── database/                   # RDS MySQL Multi-AZ
│   └── iam/                        # Users, groups, policies
├── environments/
│   ├── dev/                        # Development (cost-optimized)
│   ├── staging/                    # Staging (prod-mirror, lower cost)
│   └── prod/                       # Production (HA, encrypted, protected)
├── scripts/
│   ├── bootstrap-backend.sh        # One-time remote state setup
│   └── validate-all.sh             # Validate all environments
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SECURITY.md
│   ├── DEPLOYMENT.md
│   └── COST_ESTIMATION.md
├── .gitignore
├── LICENSE
└── README.md
```

---

## License

MIT — see [LICENSE](LICENSE).

---

Built by **Tanishq Ingawale**.
