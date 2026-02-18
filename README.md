# Log Indexer

A log indexing and search platform built with OpenSearch, providing both a web UI and REST API for log management.

## Overview

Log Indexer is a comprehensive solution for collecting, storing, and searching log data. It leverages OpenSearch for powerful full-text search capabilities and provides both a REST API and web interface for log management.

## Architecture

- **OpenSearch**: Log storage and indexing engine
- **OpenSearch Dashboards**: Web UI for log visualization
- **REST API**: Programmatic access to log data
- **Docker**: Containerization
- **Kubernetes**: Container orchestration
- **Terraform**: Infrastructure as Code
- **Ansible**: Configuration management
- **Jenkins**: CI/CD pipeline

## Features

- ✅ RESTful API for log ingestion and search
- ✅ Full-text search capabilities
- ✅ Web-based visualization with OpenSearch Dashboards
- ✅ Scalable architecture with Kubernetes
- ✅ Infrastructure as Code with Terraform
- ✅ Automated configuration with Ansible
- ✅ CI/CD pipeline with Jenkins
- ✅ Docker-based local development

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.9+ (for API development)
- Git

### Running Locally
```bash
# Start services
make up

# Check status
make status

# View logs
make logs

# Stop services
make down
```
Access the services:
- **OpenSearch**: http://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601

For detailed Docker setup instructions, see [docker/README.md](docker/README.md).

## Project Structure
```
log-indexer/
├── api/                    # REST API application
├── docker/                 # Docker and Docker Compose files
├── infrastructure/         # IaC and configuration management
│   ├── terraform/         # Terraform configurations
│   └── ansible/           # Ansible playbooks
├── kubernetes/            # Kubernetes manifests
├── jenkins/               # CI/CD pipeline definitions
├── docs/                  # Documentation
├── scripts/               # Utility scripts
└── tests/                 # End-to-end tests
```

## Documentation

- [Getting Started Guide](docs/GETTING_STARTED.md)
- [Architecture Overview](docs/architecture/ARCHITECTURE.md)

## Development Roadmap

- [ ] Phase 1: Local development setup with Docker
- [ ] Phase 2: REST API implementation
- [ ] Phase 3: Kubernetes deployment
- [ ] Phase 4: Infrastructure provisioning with Terraform
- [ ] Phase 5: Configuration management with Ansible
- [ ] Phase 6: CI/CD pipeline with Jenkins

## Contributing

This is a personal project for learning and experimentation.

## License

MIT
