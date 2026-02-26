#!/bin/bash

# Terraform deployment script
# Usage: ./scripts/terraform-apply.sh [dev|staging|production]

set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="infrastructure/terraform/environments/$ENVIRONMENT"

echo "=========================================="
echo "Applying Terraform for $ENVIRONMENT"
echo "=========================================="
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "   Usage: $0 [dev|staging|production]"
    exit 1
fi

# Check Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Verify AWS credentials
echo "1. Verifying AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo "   ✅ AWS credentials valid"
else
    echo "   ❌ AWS credentials not configured"
    echo "   Run: aws configure"
    exit 1
fi

# Navigate to environment directory
cd "$TERRAFORM_DIR"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo ""
    echo "⚠️  terraform.tfvars not found"
    echo "   Copy terraform.tfvars.example to terraform.tfvars and update values"
    read -p "Do you want to continue with defaults? (yes/no): " -r
    if [[ ! $REPLY = "yes" ]]; then
        exit 0
    fi
fi

# Initialize Terraform
echo ""
echo "2. Initializing Terraform..."
terraform init

# Validate configuration
echo ""
echo "3. Validating Terraform configuration..."
terraform validate

# Format check
echo ""
echo "4. Checking format..."
terraform fmt -check -recursive || terraform fmt -recursive

# Plan
echo ""
echo "5. Creating Terraform plan..."
terraform plan -out=tfplan

# Confirm before apply
echo ""
if [ "$ENVIRONMENT" = "production" ]; then
    echo "⚠️  WARNING: You are about to apply changes to PRODUCTION!"
    read -p "Type 'yes' to confirm: " -r
    if [[ ! $REPLY = "yes" ]]; then
        echo "Apply cancelled."
        exit 0
    fi
else
    read -p "Apply these changes? (yes/no): " -r
    if [[ ! $REPLY = "yes" ]]; then
        echo "Apply cancelled."
        exit 0
    fi
fi

# Apply
echo ""
echo "6. Applying Terraform plan..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

echo ""
echo "=========================================="
echo "✅ Terraform apply complete!"
echo "=========================================="
echo ""

# Show outputs
echo "Outputs:"
terraform output

echo ""
echo "Next steps:"
echo "1. Configure kubectl:"
terraform output -raw configure_kubectl
echo ""
echo "2. Deploy Kubernetes resources:"
echo "   ./scripts/k8s-deploy.sh $ENVIRONMENT"
echo ""
