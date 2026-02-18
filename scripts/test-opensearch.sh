#!/bin/bash

# Script to test OpenSearch setup
# Run this after starting the Docker services

set -e

echo "=========================================="
echo "Testing OpenSearch Setup"
echo "=========================================="
echo ""

# Check if OpenSearch is running
echo "1. Checking OpenSearch connection..."
if curl -s http://localhost:9200 > /dev/null; then
    echo "   ✅ OpenSearch is accessible"
else
    echo "   ❌ OpenSearch is not accessible"
    echo "   Make sure Docker services are running: make up"
    exit 1
fi

echo ""
echo "2. Checking cluster health..."
HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
echo "   Cluster status: $HEALTH"

if [ "$HEALTH" = "green" ] || [ "$HEALTH" = "yellow" ]; then
    echo "   ✅ Cluster is healthy"
else
    echo "   ❌ Cluster is not healthy"
    exit 1
fi

echo ""
echo "3. Creating test index..."
curl -s -X PUT http://localhost:9200/test-index > /dev/null
echo "   ✅ Test index created"

echo ""
echo "4. Indexing test document..."
curl -s -X POST http://localhost:9200/test-index/_doc \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Test log entry",
    "level": "INFO",
    "timestamp": "2024-01-01T12:00:00Z",
    "service": "test-service"
  }' > /dev/null
echo "   ✅ Document indexed"

echo ""
echo "5. Searching for document..."
HITS=$(curl -s http://localhost:9200/test-index/_search | grep -o '"total":{"value":[0-9]*' | grep -o '[0-9]*$')
echo "   Found $HITS document(s)"

if [ "$HITS" -gt 0 ]; then
    echo "   ✅ Search is working"
else
    echo "   ❌ Search failed"
    exit 1
fi

echo ""
echo "6. Cleaning up test index..."
curl -s -X DELETE http://localhost:9200/test-index > /dev/null
echo "   ✅ Test index deleted"

echo ""
echo "=========================================="
echo "✅ All tests passed!"
echo "=========================================="
echo ""
echo "OpenSearch is ready to use."
echo "OpenSearch Dashboards: http://localhost:5601"
echo ""
