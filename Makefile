.PHONY: help up down logs restart status clean

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
