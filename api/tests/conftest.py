"""
Pytest configuration and fixtures
"""
import pytest


@pytest.fixture
def sample_log():
    """Sample log entry for testing"""
    return {
        "level": "INFO",
        "message": "Sample log message",
        "service": "test-service",
        "host": "test-host",
        "metadata": {
            "user_id": "123",
            "request_id": "abc-def"
        }
    }


@pytest.fixture
def sample_logs():
    """Multiple sample log entries for testing"""
    return [
        {
            "level": "INFO",
            "message": "Service started",
            "service": "api"
        },
        {
            "level": "ERROR",
            "message": "Connection timeout",
            "service": "database"
        },
        {
            "level": "WARN",
            "message": "High memory usage",
            "service": "worker"
        }
    ]