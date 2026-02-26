#!/bin/bash

# Terraform destroy script
# Usage: ./scripts/terraform-destroy.sh [dev|staging|production]

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

echo "=========================================="
echo "Destroying Terraform resources for $ENVIRONMENT"
echo "=========================================="
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "   Usage: $0 [dev|staging|production]"
    exit 1
fi

# Warning
echo "⚠️  WARNING: This will destroy ALL infrastructure resources!"
echo "   Environment: $ENVIRONMENT"
echo "   This includes:"
echo "   - EKS Cluster"
echo "   - VPC and networking"
echo "   - S3 buckets"
echo "   - All associated resources"
echo ""

if [ "$ENVIRONMENT" = "production" ]; then
    echo "🚨 PRODUCTION ENVIRONMENT 🚨"
    echo ""
    read -p "Type 'destroy-production' to confirm: " -r
    if [[ ! $REPLY = "destroy-production" ]]; then
        echo "Destroy cancelled."
        exit 0
    fi
else
    read -p "Type 'yes' to confirm: " -r
    if [[ ! $REPLY = "yes" ]]; then
        echo "Destroy cancelled."
        exit 0
    fi
fi

# Navigate to environment directory
cd "$TERRAFORM_DIR"

# Show what will be destroyed
echo ""
echo "Resources to be destroyed:"
terraform plan -destroy

echo ""
read -p "Proceed with destroy? (yes/no): " -r
if [[ ! $REPLY = "yes" ]]; then
    echo "Destroy cancelled."
    exit 0
fi

# Destroy
echo ""
echo "Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "=========================================="
echo "✅ Infrastructure destroyed"
echo "=========================================="
