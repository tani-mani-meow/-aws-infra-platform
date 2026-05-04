# Cost Estimation

## Overview

All estimates are based on **us-east-1** pricing as of 2026. Actual costs may vary based on data transfer, storage growth, and usage patterns.

## Development Environment (~$63/month)

| Resource | Type | Quantity | Monthly Cost |
|----------|------|----------|-------------|
| EC2 Bastion | t3.micro | 1 | $8.50 |
| EC2 App Server | t3.micro | 1 | $8.50 |
| RDS MySQL | db.t3.micro | 1 (single-AZ) | $12.50 |
| NAT Gateway | — | 1 | $32.00 |
| EBS (bastion) | gp3, 10 GB | 1 | $0.80 |
| EBS (app) | gp3, 20 GB | 1 | $1.60 |
| Elastic IP (NAT) | — | 1 | $3.60 |
| **Total** | | | **~$67** |

> 💡 **Tip**: Destroy dev when not in use → $0/month. Use `terraform destroy` and `terraform apply` to bring it back in ~15 minutes.

## Staging Environment (~$84/month)

| Resource | Type | Quantity | Monthly Cost |
|----------|------|----------|-------------|
| EC2 Bastion | t3.micro | 1 | $8.50 |
| EC2 App Server | t3.small | 1 | $16.80 |
| RDS MySQL | db.t3.small (single-AZ) | 1 | $25.00 |
| NAT Gateway | — | 1 | $32.00 |
| EBS (bastion) | gp3, 10 GB | 1 | $0.80 |
| EBS (app) | gp3, 20 GB | 1 | $1.60 |
| Elastic IP (NAT) | — | 1 | $3.60 |
| **Total** | | | **~$88** |

## Production Environment (~$213/month)

| Resource | Type | Quantity | Monthly Cost |
|----------|------|----------|-------------|
| EC2 Bastion | t3.micro | 1 | $8.50 |
| EC2 App Servers | t3.small | 2 | $33.60 |
| RDS MySQL | db.t3.medium (Multi-AZ) | 1 | $70.00 |
| NAT Gateways | — | 3 (one per AZ) | $96.00 |
| EBS (bastion) | gp3, 10 GB | 1 | $0.80 |
| EBS (apps) | gp3, 30 GB | 2 | $4.80 |
| Elastic IPs (NAT) | — | 3 | $10.80 |
| **Total** | | | **~$225** |

## Cost Comparison

| Component | Dev | Staging | Prod |
|-----------|:---:|:-------:|:----:|
| Compute | $17.00 | $25.30 | $42.10 |
| Database | $12.50 | $25.00 | $70.00 |
| Networking | $36.40 | $36.40 | $107.60 |
| Storage | $2.40 | $2.40 | $5.60 |
| **Total** | **$68** | **$89** | **$225** |

## Cost Optimization Tips

1. **Destroy non-production environments** when not in use
2. **Reserved Instances** for prod EC2/RDS (save 30-60%)
3. **Savings Plans** for consistent compute usage
4. **Single NAT Gateway** in staging (already configured)
5. **Spot Instances** for dev EC2 (add `spot_price` to compute module)

## Free Tier Eligibility

If your AWS account is within the 12-month free tier:
- **EC2**: 750 hours/month of t2.micro (covers 1 instance)
- **RDS**: 750 hours/month of db.t2.micro (covers dev RDS)
- **S3**: 5 GB storage (covers state files)
- Estimated dev cost with free tier: **~$35/month** (mainly NAT Gateway)
