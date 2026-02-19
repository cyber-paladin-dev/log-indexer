#!/usr/bin/env python3
"""
Sample Log Generator
Generates sample logs and sends them to the Log Indexer API
"""

import requests
import random
import time
from datetime import datetime
import sys

API_URL = "http://localhost:8000"

# Sample data
LOG_LEVELS = ["INFO", "WARN", "ERROR", "DEBUG"]
SERVICES = ["api", "database", "auth-service", "payment-service", "worker"]
HOSTS = ["web-01", "web-02", "db-01", "app-01", "worker-01"]
MESSAGES = [
    "Request processed successfully",
    "Connection timeout",
    "User authentication successful",
    "Database query completed",
    "Payment processed",
    "Cache miss",
    "Rate limit exceeded",
    "Service health check passed",
    "Background job completed",
    "API endpoint called"
]


def generate_log():
    """Generate a random log entry"""
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "level": random.choice(LOG_LEVELS),
        "message": random.choice(MESSAGES),
        "service": random.choice(SERVICES),
        "host": random.choice(HOSTS),
        "metadata": {
            "request_id": f"req-{random.randint(1000, 9999)}",
            "user_id": f"user-{random.randint(1, 100)}",
            "duration_ms": random.randint(10, 500)
        }
    }


def send_log(log_entry):
    """Send log entry to the API"""
    try:
        response = requests.post(
            f"{API_URL}/logs",
            json=log_entry,
            timeout=5
        )
        response.raise_for_status()
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error sending log: {e}")
        return False


def send_bulk_logs(log_entries):
    """Send multiple log entries in bulk"""
    try:
        response = requests.post(
            f"{API_URL}/logs/bulk",
            json=log_entries,
            timeout=10
        )
        response.raise_for_status()
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error sending bulk logs: {e}")
        return False


def main():
    print("Log Generator for Log Indexer")
    print("=" * 50)
    print(f"API URL: {API_URL}")
    print("")
    
    # Check API health
    try:
        response = requests.get(f"{API_URL}/health", timeout=5)
        response.raise_for_status()
        print("✅ API is healthy")
    except requests.exceptions.RequestException:
        print("❌ API is not accessible. Make sure it's running.")
        print("   Run: make up")
        sys.exit(1)
    
    print("")
    print("Choose mode:")
    print("1. Continuous (press Ctrl+C to stop)")
    print("2. Generate N logs")
    print("3. Bulk generate")
    mode = input("Enter choice (1/2/3): ")
    
    if mode == "1":
        print("\nGenerating logs continuously...")
        print("Press Ctrl+C to stop\n")
        count = 0
        try:
            while True:
                log = generate_log()
                if send_log(log):
                    count += 1
                    print(f"✅ Sent log #{count}: [{log['level']}] {log['message']}")
                time.sleep(random.uniform(0.5, 2.0))
        except KeyboardInterrupt:
            print(f"\n\nStopped. Total logs sent: {count}")
    
    elif mode == "2":
        n = int(input("How many logs to generate? "))
        print(f"\nGenerating {n} logs...")
        success_count = 0
        for i in range(n):
            log = generate_log()
            if send_log(log):
                success_count += 1
                print(f"✅ Sent log {i+1}/{n}")
            time.sleep(0.1)
        print(f"\nCompleted. Successfully sent {success_count}/{n} logs")
    
    elif mode == "3":
        n = int(input("How many logs to generate in bulk? "))
        batch_size = int(input("Batch size (e.g., 100): "))
        print(f"\nGenerating {n} logs in batches of {batch_size}...")
        
        total_sent = 0
        for batch_start in range(0, n, batch_size):
            batch_end = min(batch_start + batch_size, n)
            batch = [generate_log() for _ in range(batch_end - batch_start)]
            
            if send_bulk_logs(batch):
                total_sent += len(batch)
                print(f"✅ Sent batch {batch_start}-{batch_end} ({len(batch)} logs)")
            
            time.sleep(0.5)
        
        print(f"\nCompleted. Successfully sent {total_sent}/{n} logs")
    
    else:
        print("Invalid choice")


if __name__ == "__main__":
    main()