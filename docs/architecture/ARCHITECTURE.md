# Log Indexer Architecture

## Overview

The Log Indexer is a distributed system for ingesting, storing, and searching log data using OpenSearch as the core storage engine.

## High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        Load Balancer                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
┌───────▼────────┐           ┌────────▼────────┐
│  API Service   │           │   Dashboards    │
│   (K8s Pods)   │           │   (K8s Pods)    │
└───────┬────────┘           └────────┬────────┘
        │                             │
        └──────────────┬──────────────┘
                       │
           ┌───────────▼───────────┐
           │  OpenSearch Cluster   │
           │   (StatefulSet)       │
           │  ┌─────┬─────┬─────┐ │
           │  │Node1│Node2│Node3│ │
           │  └─────┴─────┴─────┘ │
           └───────────┬───────────┘
                       │
              ┌────────▼────────┐
              │ Persistent      │
              │ Storage (PV)    │
              └─────────────────┘
```

## System Components

### 1. Data Layer

**OpenSearch Cluster**
- Distributed search and analytics engine
- Primary data store for log entries
- Full-text search capabilities
- Time-series optimized indexing
- Index lifecycle management for data retention

### 2. Application Layer

**REST API**
- FastAPI-based service
- Log ingestion endpoints (single and bulk)
- Search and query interface with filtering
- Health monitoring and metrics
- Horizontally scalable via Kubernetes

### 3. Presentation Layer

**OpenSearch Dashboards**
- Web-based UI for log visualization
- Custom dashboards and visualizations
- Real-time log monitoring
- Query builder interface
- Index pattern management

### 4. Infrastructure Layer

**Containerization & Orchestration**
- Docker for container packaging
- Kubernetes for container orchestration
- StatefulSets for OpenSearch (persistent storage)
- Deployments for stateless services (API, Dashboards)

**Infrastructure as Code**
- Terraform for cloud resource provisioning
- Ansible for configuration management
- Version-controlled infrastructure

### 5. CI/CD Pipeline

**Jenkins**
- Automated testing and building
- Docker image creation and registry push
- Multi-environment deployment (dev/staging/production)
- Rollback capabilities
- Integration with version control

## Data Flow

### Log Ingestion Flow

1. Client application sends log data to API endpoint
2. API validates and enriches log entry with timestamp
3. API writes log to OpenSearch index
4. OpenSearch acknowledges successful write
5. API returns confirmation with log ID to client

### Search Flow

1. User submits search query via API or Dashboards
2. Query is translated to OpenSearch Query DSL
3. OpenSearch executes distributed search across nodes
4. Results are aggregated, ranked, and filtered
5. Results returned to user with pagination

## Deployment Environments

### Development Environment
- Single-node OpenSearch for simplicity
- 1 API replica
- Local Docker Compose setup
- Fast iteration and testing

### Staging Environment
- 2-node OpenSearch cluster
- 2 API replicas for testing load balancing
- Kubernetes cluster (may be shared)
- Pre-production testing environment

### Production Environment
- 3+ node OpenSearch cluster for high availability
- 3+ API replicas with auto-scaling
- Dedicated Kubernetes cluster
- Full monitoring and alerting
- Automated backups and disaster recovery

## Scaling Strategy

### Horizontal Scaling
- **API Layer**: Add more pods based on CPU/memory metrics
- **OpenSearch**: Add data nodes to distribute load
- **Load Balancer**: Multiple instances for high availability

### Vertical Scaling
- Increase pod resource limits (CPU, memory)
- Larger OpenSearch JVM heap sizes
- More powerful compute instances

## Security Architecture

### Network Security
- Private VPC/network for all resources
- Security groups with least privilege access
- TLS/SSL encryption for all communications
- Network policies in Kubernetes to restrict pod communication

### Application Security
- API authentication (JWT tokens or API keys)
- Role-based access control (RBAC)
- Input validation and sanitization
- Rate limiting to prevent abuse

### Data Security
- Encryption at rest for stored logs
- Encryption in transit (HTTPS/TLS)
- Regular security patches and updates
- Comprehensive audit logging

## Monitoring and Observability

### Metrics
- Prometheus for metrics collection
- Grafana for visualization and dashboards
- Key metrics:
  - API request rates and latency
  - OpenSearch cluster health
  - Log ingestion throughput
  - Storage utilization

### Logging
- Application logs sent to OpenSearch
- Structured JSON logging format
- Log levels: DEBUG, INFO, WARN, ERROR
- Centralized log aggregation

### Alerting
- Alerts for critical conditions:
  - Cluster health degradation
  - High API error rates
  - Resource exhaustion
  - Deployment failures

## Data Retention and Lifecycle

### Index Lifecycle Management (ILM)
- **Hot tier**: Recent logs (0-7 days) - high performance
- **Warm tier**: Older logs (7-30 days) - reduced replicas
- **Delete**: Logs older than 30 days automatically deleted

### Backup Strategy
- Daily automated snapshots to object storage (S3/GCS)
- 30-day retention for backups
- Point-in-time recovery capability
- Tested restore procedures

## Technology Stack

### Core Technologies
- **OpenSearch**: 2.11.0 - Search and analytics
- **Python**: 3.11 - API development
- **FastAPI**: Modern Python web framework
- **Docker**: Container runtime
- **Kubernetes**: Container orchestration

### Infrastructure
- **Terraform**: Infrastructure provisioning
- **Ansible**: Configuration management
- **Jenkins**: CI/CD automation

### Cloud Providers (Choose One)
- AWS (EKS, S3, VPC)
- Google Cloud (GKE, GCS, VPC)
- Azure (AKS, Blob Storage, VNet)

## Design Principles

1. **Scalability**: System can handle increasing load by adding resources
2. **Reliability**: High availability with automatic failover
3. **Maintainability**: Infrastructure as Code for reproducibility
4. **Security**: Defense in depth with multiple security layers
5. **Observability**: Comprehensive monitoring and logging
6. **Cost Efficiency**: Resource optimization and auto-scaling

## Future Enhancements

Potential future improvements:
- Real-time streaming ingestion with Kafka
- Machine learning for log anomaly detection
- Multi-tenancy with tenant isolation
- Advanced analytics and aggregations
- GraphQL API alongside REST
- Log parsing and field extraction
- Alerting based on log patterns

## References

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Terraform Documentation](https://www.terraform.io/docs/)
