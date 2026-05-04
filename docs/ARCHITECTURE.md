# Architecture Guide

## Overview

The AWS Infrastructure Platform implements a **three-tier architecture** pattern with clear separation between public-facing, application, and data tiers. Each tier is isolated in dedicated subnets with security groups enforcing traffic flow.

## Network Topology

### VPC Design

Each environment gets its own VPC with non-overlapping CIDR blocks:

| Environment | CIDR Block | Subnets | Purpose |
|-------------|-----------|---------|---------|
| Dev | `10.0.0.0/16` | 4 (2 public, 2 private) | Development and testing |
| Staging | `10.1.0.0/16` | 4 (2 public, 2 private) | Pre-release validation |
| Prod | `172.16.0.0/16` | 6 (3 public, 3 private) | Production workloads |

### Subnet Calculation Strategy

Subnets are calculated dynamically using Terraform's `cidrsubnet()` function:

```hcl
# For a /16 VPC with subnet_newbits = 8:
# Public:  cidrsubnet("10.0.0.0/16", 8, 0) → 10.0.0.0/24 (AZ-1)
#          cidrsubnet("10.0.0.0/16", 8, 1) → 10.0.1.0/24 (AZ-2)
# Private: cidrsubnet("10.0.0.0/16", 8, 2) → 10.0.2.0/24 (AZ-1)
#          cidrsubnet("10.0.0.0/16", 8, 3) → 10.0.3.0/24 (AZ-2)
```

This approach:
- Eliminates hardcoded CIDR blocks
- Scales automatically with AZ count
- Ensures non-overlapping subnets

### Traffic Flow

```
Internet
    │
    ▼
┌───────────────┐
│ Internet GW   │ ← Attached to VPC
└───────┬───────┘
        │
    ┌───▼───────────────────────────┐
    │     Public Subnets             │
    │  ┌─────────┐  ┌─────────┐     │
    │  │ Bastion │  │   NAT   │     │
    │  │  Host   │  │ Gateway │     │
    │  └────┬────┘  └────┬────┘     │
    └───────┼─────────────┼─────────┘
            │ SSH         │ Outbound only
    ┌───────▼─────────────▼─────────┐
    │     Private Subnets            │
    │  ┌─────────┐  ┌─────────┐     │
    │  │   EC2   │──│   RDS   │     │
    │  │   App   │  │  MySQL  │     │
    │  └─────────┘  └─────────┘     │
    └───────────────────────────────┘
```

## NAT Gateway Strategy

| Environment | Strategy | Rationale |
|-------------|----------|-----------|
| Dev | Single NAT Gateway | Cost savings (~$32/mo vs ~$96/mo) |
| Staging | Single NAT Gateway | Mirrors dev; cost-effective |
| Prod | One NAT per AZ | If one AZ fails, private instances in other AZs still have internet |

## Module Dependency Graph

```
┌─────────────────┐
│   Environment   │ (dev/staging/prod main.tf)
│    Root Module   │
└────────┬────────┘
         │
    ┌────▼────┐     ┌─────────┐
    │Networking│     │   IAM   │  ← Independent (no VPC dependency)
    │  Module  │     │  Module │
    └────┬────┘     └─────────┘
         │
    ┌────▼────┐
    │Security │  ← Needs vpc_id from networking
    │ Module  │
    └────┬────┘
         │
    ┌────┼────────────────┐
    │    │                │
    ▼    ▼                ▼
┌──────┐ ┌───────┐  ┌────────┐
│Bastion│ │Compute│  │Database│
│Module │ │Module │  │ Module │
└──────┘ └───────┘  └────────┘
```

## Design Decisions Log

### Why RDS over MySQL-on-EC2?

A common approach is installing MySQL directly on an EC2 instance. While this works for prototyping, production systems benefit from managed services:
- **Automated failover** — Multi-AZ RDS handles database server failures transparently
- **Managed backups** — Point-in-time recovery without custom cron jobs
- **Automated patching** — OS and engine updates during maintenance windows
- **Encryption at rest** — KMS-managed encryption without manual setup
- **Performance Insights** — Query-level monitoring without installing tools

### Why Bastion Host over AWS Systems Manager (SSM)?

A bastion host demonstrates networking fundamentals:
- VPC routing (public vs private subnets)
- Security group chaining
- SSH key management
- NAT gateway for outbound from private subnets

SSM Session Manager is the modern, more secure alternative (no SSH keys, no open ports, CloudTrail-audited). It's a natural upgrade path documented as a future enhancement.

### Why `for_each` over `count` for IAM Users?

This project uses `for_each` for IAM users instead of `count`. The advantages:
- **Stable references**: `aws_iam_user.this["user-1"]` vs `aws_iam_user.this[0]`
- **Safe removals**: Removing a user from the middle of the list doesn't shift all indices
- **Readable plans**: `terraform plan` shows user names, not index numbers

### Why Three Environments?

- **Dev**: Fast iteration, cheap, teardown-friendly
- **Staging**: Validates that Terraform configs work at production scale before applying to prod
- **Prod**: Maximum availability, security, and data protection
