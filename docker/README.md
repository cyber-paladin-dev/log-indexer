# Docker Setup

This directory contains Docker Compose configuration for running Log Indexer locally.

## Components

- **OpenSearch**: Search and analytics engine (port 9200)
- **OpenSearch Dashboards**: Web UI for visualization (port 5601)

## Prerequisites

- Docker Desktop or Docker Engine (20.x or higher)
- Docker Compose (2.x or higher)
- At least 4GB of RAM allocated to Docker

## Quick Start

### Start Services
```bash
cd docker
docker-compose up -d
```

### Check Status
```bash
docker-compose ps
```

You should see both services running:
```
NAME                    STATUS              PORTS
opensearch              Up (healthy)        0.0.0.0:9200->9200/tcp, 0.0.0.0:9600->9600/tcp
opensearch-dashboards   Up (healthy)        0.0.0.0:5601->5601/tcp
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f opensearch
docker-compose logs -f opensearch-dashboards
```

### Stop Services
```bash
docker-compose down
```

### Clean Up (Remove Volumes)
```bash
# Warning: This will delete all indexed data
docker-compose down -v
```

## Accessing Services

Once the services are running and healthy:

### OpenSearch
```bash
# Check cluster health
curl http://localhost:9200/_cluster/health

# Expected response:
# {"cluster_name":"opensearch-cluster","status":"green",...}
```

### OpenSearch Dashboards

Open your browser and navigate to: http://localhost:5601

**First Time Setup:**
1. Click on "Explore on my own"
2. You'll see the Dashboards home page
3. Index patterns will be created when you start ingesting logs

## Configuration Details

### OpenSearch Configuration

- **Cluster name**: opensearch-cluster
- **Node name**: opensearch-node1
- **Discovery type**: single-node (for local development)
- **Memory**: 512MB heap (configurable)
- **Security**: Disabled for local development (enable in production)
- **Persistent storage**: Docker volume `opensearch-data`

### Network

All services are connected via the `log-indexer-net` bridge network, allowing them to communicate using service names (e.g., `http://opensearch:9200`).

### Health Checks

Both services have health checks configured:
- **OpenSearch**: Checks cluster health endpoint
- **Dashboards**: Checks status API endpoint

Services report as "healthy" once they're fully operational.

## Testing the Setup

### 1. Verify OpenSearch
```bash
# Cluster health
curl http://localhost:9200/_cluster/health?pretty

# Create a test index
curl -X PUT http://localhost:9200/test-index

# Index a document
curl -X POST http://localhost:9200/test-index/_doc \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello from OpenSearch!", "timestamp": "2024-01-01T12:00:00Z"}'

# Search
curl http://localhost:9200/test-index/_search?pretty

# Delete test index
curl -X DELETE http://localhost:9200/test-index
```

### 2. Verify OpenSearch Dashboards

1. Open http://localhost:5601
2. Navigate using the hamburger menu (☰)
3. Go to "Management" → "Dev Tools"
4. Try some queries in the console

## Data Persistence

Data is persisted in Docker volumes:

**View volumes:**
```bash
docker volume ls | grep opensearch
```

**Inspect volume:**
```bash
docker volume inspect docker_opensearch-data
```

**Backup data:**
```bash
docker run --rm -v docker_opensearch-data:/data -v $(pwd):/backup ubuntu tar czf /backup/opensearch-backup.tar.gz /data
```

**Restore data:**
```bash
docker run --rm -v docker_opensearch-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/opensearch-backup.tar.gz -C /
```

## Resources

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [OpenSearch Dashboards Documentation](https://opensearch.org/docs/latest/dashboards/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
