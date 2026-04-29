#!/bin/bash
# ==============================================================================
# Bootstrap Terraform Remote State Backend
# ==============================================================================
# Run this script ONCE to create the S3 bucket and DynamoDB table used for
# Terraform remote state storage and locking.
#
# Usage: ./scripts/bootstrap-backend.sh [region] [project-name]
# ==============================================================================

set -euo pipefail

REGION="${1:-us-east-1}"
PROJECT="${2:-aws-infra-platform}"
BUCKET="${PROJECT}-tfstate"
TABLE="${PROJECT}-tflock"

echo "=============================================="
echo "  Bootstrapping Terraform Backend"
echo "=============================================="
echo "Region:         ${REGION}"
echo "S3 Bucket:      ${BUCKET}"
echo "DynamoDB Table: ${TABLE}"
echo "=============================================="
echo ""

# --- Create S3 Bucket ---
echo "📦 Creating S3 bucket: ${BUCKET}..."
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "   Bucket already exists, skipping."
else
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --region "${REGION}" \
    $([ "${REGION}" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=${REGION}")

  # Enable versioning (state file history)
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET}" \
    --versioning-configuration Status=Enabled

  # Enable server-side encryption
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }]
    }'

  # Block public access
  aws s3api put-public-access-block \
    --bucket "${BUCKET}" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'

  echo "   ✅ S3 bucket created with versioning, encryption, and public access block."
fi

# --- Create DynamoDB Table ---
echo ""
echo "🔒 Creating DynamoDB table: ${TABLE}..."
if aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "   Table already exists, skipping."
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

  echo "   ⏳ Waiting for table to become active..."
  aws dynamodb wait table-exists --table-name "${TABLE}" --region "${REGION}"
  echo "   ✅ DynamoDB table created."
fi

echo ""
echo "=============================================="
echo "  ✅ Backend bootstrap complete!"
echo "=============================================="
echo ""
echo "You can now run 'terraform init' in any environment."
echo ""
