#!/bin/bash

# Kubernetes cleanup script for Log Indexer
# Usage: ./scripts/k8s-cleanup.sh [dev|staging|production]

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="log-indexer-$ENVIRONMENT"

echo "=========================================="
echo "Cleaning up Log Indexer from $ENVIRONMENT"
echo "=========================================="
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "   Usage: $0 [dev|staging|production]"
    exit 1
fi

# Confirm deletion
echo "⚠️  WARNING: This will delete all resources in namespace $NAMESPACE"
echo "   This includes all data stored in persistent volumes!"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " -r
if [[ ! $REPLY = "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting resources..."
kubectl delete -k kubernetes/overlays/$ENVIRONMENT

echo ""
echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true

echo ""
echo "=========================================="
echo "✅ Cleanup complete!"
echo "=========================================="
