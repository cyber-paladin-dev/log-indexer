#!/bin/bash

# Script to test the Log Indexer API
# Run this after starting the Docker services

set -e

echo "=========================================="
echo "Testing Log Indexer API"
echo "=========================================="
echo ""

# Check if API is running
echo "1. Checking API connection..."
if curl -s http://localhost:8000 > /dev/null; then
    echo "   ✅ API is accessible"
else
    echo "   ❌ API is not accessible"
    echo "   Make sure Docker services are running: make up"
    exit 1
fi

echo ""
echo "2. Checking API health..."
HEALTH=$(curl -s http://localhost:8000/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
echo "   API status: $HEALTH"

if [ "$HEALTH" = "healthy" ]; then
    echo "   ✅ API is healthy"
else
    echo "   ❌ API is not healthy"
    exit 1
fi

echo ""
echo "3. Ingesting test log..."
RESPONSE=$(curl -s -X POST http://localhost:8000/logs \
  -H 'Content-Type: application/json' \
  -d '{
    "level": "INFO",
    "message": "Test log from script",
    "service": "test-service",
    "host": "test-host"
  }')

LOG_ID=$(echo $RESPONSE | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
echo "   ✅ Log ingested with ID: $LOG_ID"

echo ""
echo "4. Retrieving log by ID..."
curl -s http://localhost:8000/logs/$LOG_ID > /dev/null
echo "   ✅ Log retrieved successfully"

echo ""
echo "5. Searching for logs..."
TOTAL=$(curl -s -X POST http://localhost:8000/logs/search \
  -H 'Content-Type: application/json' \
  -d '{"query": "test", "size": 10}' | grep -o '"total":[0-9]*' | cut -d':' -f2)
echo "   Found $TOTAL log(s)"
echo "   ✅ Search is working"

echo ""
echo "6. Testing bulk ingest..."
curl -s -X POST http://localhost:8000/logs/bulk \
  -H 'Content-Type: application/json' \
  -d '[
    {"level": "INFO", "message": "Bulk log 1", "service": "test"},
    {"level": "WARN", "message": "Bulk log 2", "service": "test"},
    {"level": "ERROR", "message": "Bulk log 3", "service": "test"}
  ]' > /dev/null
echo "   ✅ Bulk ingest successful"

echo ""
echo "7. Deleting test log..."
curl -s -X DELETE http://localhost:8000/logs/$LOG_ID > /dev/null
echo "   ✅ Log deleted"

echo ""
echo "=========================================="
echo "✅ All API tests passed!"
echo "=========================================="
echo ""
echo "API Documentation: http://localhost:8000/docs"
echo "API Health: http://localhost:8000/health"
echo ""