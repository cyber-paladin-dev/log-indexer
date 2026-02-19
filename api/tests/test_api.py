"""
Tests for Log Indexer API
"""
import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test root endpoint returns API info"""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "version" in response.json()
    assert "endpoints" in response.json()


def test_health_check():
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code in [200, 503]
    assert "status" in response.json()


def test_ingest_log(sample_log):
    """Test log ingestion"""
    response = client.post("/logs", json=sample_log)
    assert response.status_code == 201
    assert "id" in response.json()
    assert response.json()["status"] == "indexed"


def test_ingest_bulk_logs(sample_logs):
    """Test bulk log ingestion"""
    response = client.post("/logs/bulk", json=sample_logs)
    assert response.status_code == 201
    assert "indexed" in response.json()
    assert response.json()["indexed"] == 3


def test_search_logs():
    """Test log search"""
    search_query = {
        "query": "test",
        "size": 10,
        "from": 0
    }
    response = client.post("/logs/search", json=search_query)
    assert response.status_code == 200
    assert "total" in response.json()
    assert "results" in response.json()


def test_search_logs_with_filters():
    """Test log search with filters"""
    search_query = {
        "level": "ERROR",
        "service": "database",
        "size": 10
    }
    response = client.post("/logs/search", json=search_query)
    assert response.status_code == 200
    results = response.json()["results"]
    if results:
        assert all(log["level"] == "ERROR" for log in results)


def test_get_nonexistent_log():
    """Test retrieving non-existent log"""
    response = client.get("/logs/nonexistent-id")
    assert response.status_code == 404


def test_delete_nonexistent_log():
    """Test deleting non-existent log"""
    response = client.delete("/logs/nonexistent-id")
    assert response.status_code == 404


def test_log_lifecycle(sample_log):
    """Test complete log lifecycle: create, retrieve, delete"""
    # Create log
    create_response = client.post("/logs", json=sample_log)
    assert create_response.status_code == 201
    log_id = create_response.json()["id"]
    
    # Retrieve log
    get_response = client.get(f"/logs/{log_id}")
    assert get_response.status_code == 200
    assert get_response.json()["message"] == sample_log["message"]
    
    # Delete log
    delete_response = client.delete(f"/logs/{log_id}")
    assert delete_response.status_code == 200
    
    # Verify deletion
    verify_response = client.get(f"/logs/{log_id}")
    assert verify_response.status_code == 404