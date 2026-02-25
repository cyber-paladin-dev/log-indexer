# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying Log Indexer to a Kubernetes cluster.

## Architecture

The deployment consists of:
- **OpenSearch StatefulSet**: Persistent storage with stable network identities
- **OpenSearch Dashboards Deployment**: Web UI for visualization
- **API Deployment**: REST API service
- **Services**: ClusterIP for internal communication, LoadBalancer for external access
- **ConfigMaps**: Environment-specific configuration

## Prerequisites

- Kubernetes cluster (1.24+)
- kubectl configured to access your cluster
- kustomize (included in kubectl 1.14+)
- Sufficient cluster resources:
  - Dev: 2 CPU, 4GB RAM
  - Staging: 4 CPU, 8GB RAM
  - Production: 8 CPU, 16GB RAM

## Structure
```
kubernetes/
├── base/                   # Base configurations
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── opensearch-statefulset.yaml
│   ├── opensearch-dashboards-deployment.yaml
│   ├── api-deployment.yaml
│   └── kustomization.yaml
└── overlays/              # Environment-specific overlays
    ├── dev/
    ├── staging/
    └── production/
```

## Deployment

### Deploy to Development
```bash
# Apply all resources
kubectl apply -k kubernetes/overlays/dev

# Check deployment status
kubectl get pods -n log-indexer-dev

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=opensearch -n log-indexer-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=log-indexer-api -n log-indexer-dev --timeout=300s
```

### Deploy to Staging
```bash
kubectl apply -k kubernetes/overlays/staging

# Check status
kubectl get all -n log-indexer-staging
```

### Deploy to Production
```bash
# Review changes first
kubectl diff -k kubernetes/overlays/production

# Apply
kubectl apply -k kubernetes/overlays/production

# Monitor rollout
kubectl rollout status deployment/log-indexer-api -n log-indexer-prod
kubectl rollout status statefulset/opensearch -n log-indexer-prod
```

## Accessing Services

### Port Forwarding (Development)
```bash
# API
kubectl port-forward -n log-indexer-dev svc/log-indexer-api-service 8000:8000

# OpenSearch
kubectl port-forward -n log-indexer-dev svc/opensearch-service 9200:9200

# OpenSearch Dashboards
kubectl port-forward -n log-indexer-dev svc/opensearch-dashboards-service 5601:5601
```

Then access:
- API: http://localhost:8000
- OpenSearch: http://localhost:9200
- Dashboards: http://localhost:5601

### LoadBalancer (Cloud)

Get external IPs:
```bash
kubectl get svc -n log-indexer-dev
```

Access services using the EXTERNAL-IP addresses.

## Configuration

### Environment Variables

Edit `kubernetes/base/configmap.yaml` or use overlays:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-indexer-config
data:
  OPENSEARCH_HOST: "opensearch-service"
  OPENSEARCH_PORT: "9200"
  LOG_LEVEL: "INFO"
```

### Scaling

**Scale API:**
```bash
kubectl scale deployment log-indexer-api --replicas=5 -n log-indexer-dev
```

**Scale OpenSearch:**
```bash
kubectl scale statefulset opensearch --replicas=3 -n log-indexer-dev
```

Or edit the replica patches in overlays.

### Resource Limits

Adjust resources in the overlay patches:
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## Monitoring

### Check Pod Status
```bash
# All pods
kubectl get pods -n log-indexer-dev

# Specific pod
kubectl describe pod <pod-name> -n log-indexer-dev
```

### View Logs
```bash
# API logs
kubectl logs -f deployment/log-indexer-api -n log-indexer-dev

# OpenSearch logs
kubectl logs -f statefulset/opensearch -n log-indexer-dev

# Dashboards logs
kubectl logs -f deployment/opensearch-dashboards -n log-indexer-dev
```

### Execute Commands in Pods
```bash
# Shell into API pod
kubectl exec -it deployment/log-indexer-api -n log-indexer-dev -- /bin/bash

# Shell into OpenSearch pod
kubectl exec -it opensearch-0 -n log-indexer-dev -- /bin/bash
```

## Troubleshooting

### Pods Not Starting

**Check pod events:**
```bash
kubectl describe pod <pod-name> -n log-indexer-dev
```

**Common issues:**
- Insufficient resources: Increase node capacity
- Image pull errors: Check image name and registry credentials
- Volume mount issues: Check PVC status

### OpenSearch Not Healthy

**Check logs:**
```bash
kubectl logs statefulset/opensearch -n log-indexer-dev
```

**Common issues:**
- Memory limits too low: Increase memory allocation
- Disk space: Check PVC size
- vm.max_map_count: May need to configure on nodes

### API Can't Connect to OpenSearch

**Check service:**
```bash
kubectl get svc opensearch-service -n log-indexer-dev
```

**Test connection from API pod:**
```bash
kubectl exec -it deployment/log-indexer-api -n log-indexer-dev -- curl http://opensearch-service:9200
```

### Persistent Volume Issues

**Check PVCs:**
```bash
kubectl get pvc -n log-indexer-dev
```

**Check PVs:**
```bash
kubectl get pv
```

If PVC is pending, check:
- Storage class exists
- Sufficient storage available
- Access mode compatibility

## Updates and Rollbacks

### Update API Image
```bash
# Edit deployment to change image
kubectl set image deployment/log-indexer-api api=your-registry/log-indexer-api:v2.0 -n log-indexer-dev

# Check rollout status
kubectl rollout status deployment/log-indexer-api -n log-indexer-dev
```

### Rollback Deployment
```bash
# View rollout history
kubectl rollout history deployment/log-indexer-api -n log-indexer-dev

# Rollback to previous version
kubectl rollout undo deployment/log-indexer-api -n log-indexer-dev

# Rollback to specific revision
kubectl rollout undo deployment/log-indexer-api --to-revision=2 -n log-indexer-dev
```

### Update ConfigMap
```bash
# Edit configmap
kubectl edit configmap log-indexer-config -n log-indexer-dev

# Restart pods to pick up changes
kubectl rollout restart deployment/log-indexer-api -n log-indexer-dev
```

## Cleanup

### Delete Specific Environment
```bash
# Delete dev environment
kubectl delete namespace log-indexer-dev
```

### Delete All Resources
```bash
kubectl delete -k kubernetes/overlays/dev
kubectl delete -k kubernetes/overlays/staging
kubectl delete -k kubernetes/overlays/production
```

**Warning:** This will delete all data in persistent volumes!

## Best Practices

1. **Use Kustomize overlays** for environment-specific configuration
2. **Set resource limits** to prevent resource exhaustion
3. **Use health checks** (liveness and readiness probes)
4. **Enable persistent storage** for OpenSearch data
5. **Use namespaces** to isolate environments
6. **Tag images** with specific versions (not `latest`)
7. **Monitor resource usage** and scale accordingly
8. **Backup persistent volumes** regularly
9. **Use secrets** for sensitive data (not ConfigMaps)
10. **Implement network policies** for security

## Production Checklist

Before deploying to production:

- [ ] Resource limits properly configured
- [ ] Persistent volumes configured and tested
- [ ] Health checks working correctly
- [ ] Monitoring and alerting set up
- [ ] Backup strategy implemented
- [ ] Security policies applied
- [ ] Network policies configured
- [ ] SSL/TLS certificates configured
- [ ] Secrets management implemented
- [ ] Disaster recovery plan documented
- [ ] Scaling strategy defined
- [ ] Load testing completed

## Security Notes

**Current Configuration:**
- Security plugins disabled (for development)
- No authentication required
- No encryption in transit

**For Production:**
1. Enable OpenSearch security plugin
2. Configure SSL/TLS certificates
3. Set up authentication (SAML, LDAP, etc.)
4. Implement RBAC
5. Use Kubernetes secrets for credentials
6. Enable network policies
7. Use pod security policies/standards

## Next Steps

- Add ingress for external access
- Implement autoscaling (HPA)
- Add monitoring with Prometheus
- Set up centralized logging
- Implement backup automation
- Configure alerting rules
- Add network policies
- Enable SSL/TLS
