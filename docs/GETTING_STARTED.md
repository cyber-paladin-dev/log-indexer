# Getting Started with Log Indexer

This guide will help you get the Log Indexer up and running on your local machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.x or higher)
- **Docker Compose** (version 2.x or higher)
- **Python** (version 3.9 or higher) - for API development
- **Git** - for version control
- **Make** (optional) - for convenience commands

## Quick Start

*Note: The quick start setup will be available after the Docker configuration is added.*

## Accessing Services

Once running, you will be able to access:

- **OpenSearch**: http://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601
- **Log Indexer API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

## API Endpoints

The API will provide the following endpoints:

- `POST /logs` - Ingest log data
- `POST /logs/bulk` - Bulk ingest log data
- `POST /logs/search` - Search logs with filters
- `GET /logs/{id}` - Retrieve specific log entry
- `DELETE /logs/{id}` - Delete specific log entry
- `GET /health` - Health check endpoint

## Development Workflow

The typical development workflow will be:

1. Make changes locally
2. Test with Docker Compose
3. Run unit tests
4. Commit and push to GitHub
5. Jenkins pipeline automatically deploys to dev
6. Promote to staging/production as needed

## Project Structure Overview
```
log-indexer/
├── api/                    # REST API application
│   ├── src/               # API source code
│   ├── tests/             # API tests
│   └── Dockerfile         # API container definition
├── docker/                # Docker Compose configuration
├── kubernetes/            # Kubernetes manifests
│   ├── base/             # Base configurations
│   └── overlays/         # Environment-specific overlays
├── infrastructure/        # Infrastructure as Code
│   ├── terraform/        # Terraform modules
│   └── ansible/          # Ansible playbooks
├── jenkins/              # CI/CD pipeline
├── docs/                 # Documentation
├── scripts/              # Utility scripts
└── tests/                # End-to-end tests
```

## Next Steps

The project will be built incrementally:

1. **Docker Setup** - Docker Compose for local development
2. **API Development** - FastAPI-based REST API
3. **Kubernetes Deployment** - Container orchestration
4. **Infrastructure Provisioning** - Terraform setup
5. **Configuration Management** - Ansible playbooks
6. **CI/CD Pipeline** - Jenkins automation

## Getting Help

- Check the [Architecture Documentation](architecture/ARCHITECTURE.md)
- Review the main [README](../README.md)
- Open an issue on GitHub

Stay tuned for updates as the project develops! 🚀
