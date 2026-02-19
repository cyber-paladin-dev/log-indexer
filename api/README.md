# Log Indexer API

REST API for ingesting and searching log data stored in OpenSearch.

## Features

- **Log Ingestion**: Single and bulk log entry ingestion
- **Full-Text Search**: Search logs by message content
- **Filtering**: Filter by log level, service, timestamp range
- **CRUD Operations**: Create, read, and delete log entries
- **Health Checks**: Monitor API and OpenSearch status
- **Auto-documentation**: Interactive API docs with Swagger UI

## API Endpoints

### Health & Info

- `GET /` - API information
- `GET /health` - Health check endpoint
- `GET /docs` - Interactive API documentation (Swagger UI)

### Log Management

- `POST /logs` - Ingest a single log entry
- `POST /logs/bulk` - Ingest multiple log entries
- `POST /logs/search` - Search logs with filters
- `GET /logs/{id}` - Get specific log entry
- `DELETE /logs/{id}` - Delete specific log entry

## Local Development

### Setup
```bash
# Navigate to API directory
cd api

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Configuration

Create a `.env` file in the `api` directory:
```env
OPENSEARCH_HOST=localhost
OPENSEARCH_PORT=9200
API_PORT=8000
LOG_LEVEL=INFO
INDEX_NAME=logs
```

### Run Locally

**Option 1: With Docker (Recommended)**
```bash
# From project root
cd docker
docker-compose up -d
```

The API will be available at `http://localhost:8000`

**Option 2: Without Docker (Development)**

Make sure OpenSearch is running first, then:
```bash
cd api
source venv/bin/activate
python src/main.py
```

### Run Tests
```bash
cd api
source venv/bin/activate

# Run all tests
pytest

# Run with coverage
pytest --cov=src tests/

# Run specific test file
pytest tests/test_api.py -v

# Run with verbose output
pytest -v
```

## Usage Examples

### Check Health
```bash
curl http://localhost:8000/health
```

### Ingest a Log
```bash
curl -X POST http://localhost:8000/logs \
  -H "Content-Type: application/json" \
  -d '{
    "level": "INFO",
    "message": "User logged in successfully",
    "service": "auth-service",
    "host": "web-01",
    "metadata": {
      "user_id": "12345",
      "ip": "192.168.1.1"
    }
  }'
```

### Bulk Ingest
```bash
curl -X POST http://localhost:8000/logs/bulk \
  -H "Content-Type: application/json" \
  -d '[
    {
      "level": "INFO",
      "message": "Service started",
      "service": "api"
    },
    {
      "level": "ERROR",
      "message": "Connection failed",
      "service": "database"
    }
  ]'
```

### Search Logs
```bash
# Simple search
curl -X POST http://localhost:8000/logs/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "error",
    "size": 50
  }'

# Search with filters
curl -X POST http://localhost:8000/logs/search \
  -H "Content-Type: application/json" \
  -d '{
    "level": "ERROR",
    "service": "auth-service",
    "start_time": "2024-01-01T00:00:00Z",
    "end_time": "2024-01-31T23:59:59Z",
    "size": 100
  }'
```

### Get Specific Log
```bash
curl http://localhost:8000/logs/{log_id}
```

### Delete Log
```bash
curl -X DELETE http://localhost:8000/logs/{log_id}
```

## Interactive API Documentation

Once the API is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

You can test all endpoints directly from the Swagger UI.

## Code Quality
```bash
# Format code
black src/ tests/
isort src/ tests/

# Lint
flake8 src/ tests/

# All at once
black src/ tests/ && isort src/ tests/ && flake8 src/ tests/
```

## Project Structure
```
api/
├── src/
│   └── main.py              # Main application
├── tests/
│   ├── test_api.py          # API tests
│   └── conftest.py          # Test fixtures
├── Dockerfile               # Container definition
├── requirements.txt         # Python dependencies
├── .env.example            # Example environment variables
└── README.md               # This file
```

## OpenSearch Index Structure
```json
{
  "mappings": {
    "properties": {
      "timestamp": {"type": "date"},
      "level": {"type": "keyword"},
      "message": {"type": "text"},
      "service": {"type": "keyword"},
      "host": {"type": "keyword"},
      "metadata": {"type": "object"}
    }
  }
}
```

## Troubleshooting

### Cannot connect to OpenSearch

Make sure OpenSearch is running:
```bash
curl http://localhost:9200/_cluster/health
```

If not, start it:
```bash
cd docker
docker-compose up -d opensearch
```

### Port 8000 already in use

Change the API port in `.env`:
```env
API_PORT=8001
```

### Import errors

Make sure you're in the virtual environment:
```bash
source venv/bin/activate
pip install -r requirements.txt
```
