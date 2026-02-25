#!/bin/bash

# Kubernetes deployment script for Log Indexer
# Usage: ./scripts/k8s-deploy.sh [dev|staging|production]

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="log-indexer-$ENVIRONMENT"

echo "=========================================="
echo "Deploying Log Indexer to $ENVIRONMENT"
echo "=========================================="
echo ""

# Check kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check cluster connection
echo "1. Checking cluster connection..."
if kubectl cluster-info &> /dev/null; then
    echo "   ✅ Connected to Kubernetes cluster"
else
    echo "   ❌ Cannot connect to Kubernetes cluster"
    echo "   Configure kubectl with: kubectl config use-context <context-name>"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "   Usage: $0 [dev|staging|production]"
    exit 1
fi

# Confirm production deployment
if [ "$ENVIRONMENT" = "production" ]; then
    echo ""
    echo "⚠️  WARNING: You are about to deploy to PRODUCTION!"
    read -p "Are you sure? (type 'yes' to confirm): " -r
    if [[ ! $REPLY = "yes" ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

echo ""
echo "2. Applying Kubernetes manifests..."
kubectl apply -k kubernetes/overlays/$ENVIRONMENT

echo ""
echo "3. Waiting for deployments to be ready..."

# Wait for OpenSearch
echo "   Waiting for OpenSearch..."
kubectl wait --for=condition=ready pod -l app=opensearch -n $NAMESPACE --timeout=300s || true

# Wait for API
echo "   Waiting for API..."
kubectl wait --for=condition=ready pod -l app=log-indexer-api -n $NAMESPACE --timeout=300s || true

# Wait for Dashboards
echo "   Waiting for Dashboards..."
kubectl wait --for=condition=ready pod -l app=opensearch-dashboards -n $NAMESPACE --timeout=300s || true

echo ""
echo "4. Checking deployment status..."
kubectl get all -n $NAMESPACE

echo ""
echo "=========================================="
echo "✅ Deployment complete!"
echo "=========================================="
echo ""
echo "Access services:"
echo ""
echo "Port forwarding commands:"
echo "  API:        kubectl port-forward -n $NAMESPACE svc/log-indexer-api-service 8000:8000"
echo "  OpenSearch: kubectl port-forward -n $NAMESPACE svc/opensearch-service 9200:9200"
echo "  Dashboards: kubectl port-forward -n $NAMESPACE svc/opensearch-dashboards-service 5601:5601"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl logs -f deployment/log-indexer-api -n $NAMESPACE"
echo ""
