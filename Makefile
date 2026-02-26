.PHONY: help up down logs restart status clean test-api generate-logs api-logs k8s-deploy k8s-deploy-dev k8s-deploy-staging k8s-deploy-prod k8s-cleanup k8s-status k8s-logs tf-init tf-plan tf-apply tf-destroy tf-output

help:
	@echo "Log Indexer - Available commands:"
	@echo ""
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make logs     - Follow logs from all services"
	@echo "  make restart  - Restart all services"
	@echo "  make status   - Show service status"
	@echo "  make clean    - Stop services and remove volumes"
	@echo ""

up:
	@echo "Starting Log Indexer services..."
	cd docker && docker-compose up -d
	@echo ""
	@echo "Services starting. Wait a moment for health checks..."
	@echo "OpenSearch: http://localhost:9200"
	@echo "OpenSearch Dashboards: http://localhost:5601"

down:
	@echo "Stopping services..."
	cd docker && docker-compose down

logs:
	cd docker && docker-compose logs -f

restart:
	@echo "Restarting services..."
	cd docker && docker-compose restart

status:
	cd docker && docker-compose ps

clean:
	@echo "Stopping services and removing volumes..."
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd docker && docker-compose down -v; \
	fi

test-api:
	@echo "Testing API..."
	./scripts/test-api.sh

generate-logs:
	@echo "Starting log generator..."
	python3 scripts/generate-logs.py

api-logs:
	cd docker && docker-compose logs -f api

# Kubernetes deployment
k8s-deploy-dev:
	@echo "Deploying to Kubernetes (dev)..."
	./scripts/k8s-deploy.sh dev

k8s-deploy-staging:
	@echo "Deploying to Kubernetes (staging)..."
	./scripts/k8s-deploy.sh staging

k8s-deploy-prod:
	@echo "Deploying to Kubernetes (production)..."
	./scripts/k8s-deploy.sh production

k8s-cleanup:
	@echo "Cleaning up Kubernetes resources..."
	./scripts/k8s-cleanup.sh $(ENV)

k8s-status:
	@echo "Kubernetes status (dev)..."
	kubectl get all -n log-indexer-dev

k8s-logs:
	@echo "Following API logs (dev)..."
	kubectl logs -f deployment/log-indexer-api -n log-indexer-dev

# Terraform commands
tf-init:
	@echo "Initializing Terraform..."
	cd infrastructure/terraform/environments/dev && terraform init

tf-plan:
	@echo "Planning Terraform changes..."
	cd infrastructure/terraform/environments/dev && terraform plan

tf-apply:
	@echo "Applying Terraform..."
	./scripts/terraform-apply.sh dev

tf-destroy:
	@echo "Destroying Terraform resources..."
	./scripts/terraform-destroy.sh dev

tf-output:
	@echo "Terraform outputs:"
	cd infrastructure/terraform/environments/dev && terraform output
