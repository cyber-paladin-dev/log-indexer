# Terraform Infrastructure

This directory contains Terraform configurations for provisioning cloud infrastructure for Log Indexer.

## Overview

The infrastructure is organized into:
- **modules/**: Reusable Terraform modules (network, kubernetes, storage)
- **environments/**: Environment-specific configurations (dev, staging, production)

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with credentials
- Appropriate AWS permissions (VPC, EKS, S3, IAM)

## Quick Start

### 1. Initialize Terraform
```bash
cd infrastructure/terraform/environments/dev
terraform init
```

### 2. Create terraform.tfvars
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Plan Infrastructure
```bash
terraform plan
```

### 4. Apply Infrastructure
```bash
terraform apply
```

### 5. Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name log-indexer-dev
kubectl get nodes
```

## Module Documentation

### Network Module

Creates VPC with public and private subnets, NAT gateways, and route tables.

**Inputs:**
- `environment`: Environment name
- `vpc_cidr`: VPC CIDR block
- `availability_zones`: List of AZs
- `tags`: Resource tags

**Outputs:**
- `vpc_id`: VPC ID
- `private_subnet_ids`: Private subnet IDs
- `public_subnet_ids`: Public subnet IDs

### Kubernetes Module

Creates AWS EKS cluster with managed node groups.

**Inputs:**
- `cluster_name`: EKS cluster name
- `cluster_version`: Kubernetes version
- `vpc_id`: VPC ID
- `private_subnet_ids`: Subnet IDs for nodes
- `node_groups`: Node group configurations

**Outputs:**
- `cluster_name`: EKS cluster name
- `cluster_endpoint`: API server endpoint
- `cluster_security_group_id`: Cluster security group

### Storage Module

Creates S3 bucket for OpenSearch backups with lifecycle policies.

**Inputs:**
- `environment`: Environment name
- `tags`: Resource tags

**Outputs:**
- `backup_bucket_name`: S3 bucket name
- `backup_bucket_arn`: S3 bucket ARN

## Environment Configuration

### Development
- Single NAT Gateway (cost optimization)
- Smaller instance types (t3.medium)
- 2 nodes (min 1, max 4)
- Single availability zone option

### Staging
- Multi-AZ NAT Gateways
- Medium instance types (t3.large)
- 2 nodes (min 2, max 6)
- Similar to production but smaller

### Production
- Multi-AZ NAT Gateways
- Large instance types (t3.xlarge)
- 3 nodes (min 3, max 10)
- High availability configuration
- Enhanced monitoring

## Remote State

For team collaboration, configure remote state:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "log-indexer/dev/terraform.tfstate"
    region = "us-west-2"
    
    # Enable state locking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

Create the S3 bucket and DynamoDB table:
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-west-2

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

## Common Commands
```bash
# Initialize
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure
terraform destroy
```

## Cost Estimation

Before applying, estimate costs:
```bash
# Using Infracost (install from https://www.infracost.io)
infracost breakdown --path .
```

Approximate monthly costs:
- **Dev**: $100-150 (t3.medium × 2, single NAT)
- **Staging**: $200-300 (t3.large × 2, multi-NAT)
- **Production**: $500-800 (t3.xlarge × 3, multi-NAT, HA)

## Troubleshooting

### Authentication Issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Configure AWS profile
export AWS_PROFILE=your-profile
```

### Module Not Found
```bash
# Re-initialize
terraform init -upgrade
```

### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

### EKS Cluster Access
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name log-indexer-dev

# Verify access
kubectl get nodes
```

## Cleanup

To destroy all infrastructure:
```bash
cd infrastructure/terraform/environments/dev

# Review what will be destroyed
terraform plan -destroy

# Destroy
terraform destroy
```

**Warning:** This will delete all resources including data in persistent volumes!

## Security Best Practices

1. **Never commit** `.tfvars` files with sensitive data
2. **Use remote state** with encryption
3. **Enable state locking** to prevent concurrent modifications
4. **Use IAM roles** instead of access keys when possible
5. **Enable CloudTrail** for audit logging
6. **Use separate AWS accounts** for each environment
7. **Implement least privilege** IAM policies
8. **Enable encryption** for all resources
9. **Regular security audits** with tools like `tfsec`
10. **Use tagged releases** for module versions

## Advanced Topics

### Multi-Region Deployment

To deploy across multiple regions, create separate configurations or use workspaces.

### Custom VPC Configuration

Modify `modules/network/main.tf` to customize:
- Subnet sizing
- NAT Gateway configuration
- VPC endpoints
- Network ACLs

### Auto-Scaling Configuration

Adjust node group settings in `terraform.tfvars`:
```hcl
node_groups = {
  general = {
    desired_size   = 3
    min_size       = 2
    max_size       = 10
    instance_types = ["t3.large", "t3.xlarge"]
  }
}
```

## Next Steps

After provisioning infrastructure:

1. Configure kubectl access
2. Deploy Kubernetes manifests
3. Configure monitoring and logging
4. Set up backup automation
5. Implement CI/CD pipeline

## Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Modules](https://registry.terraform.io/)
