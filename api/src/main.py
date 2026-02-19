"""
Log Indexer API
Main application entry point
"""
import os
import logging
from datetime import datetime
from typing import Optional, List, Dict, Any

from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from opensearchpy import OpenSearch
from opensearchpy.exceptions import OpenSearchException

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# OpenSearch configuration
OPENSEARCH_HOST = os.getenv("OPENSEARCH_HOST", "localhost")
OPENSEARCH_PORT = int(os.getenv("OPENSEARCH_PORT", "9200"))
INDEX_NAME = os.getenv("INDEX_NAME", "logs")

# Initialize FastAPI app
app = FastAPI(
    title="Log Indexer API",
    description="REST API for log ingestion and search using OpenSearch",
    version="1.0.0"
)

# Initialize OpenSearch client
opensearch_client = OpenSearch(
    hosts=[{"host": OPENSEARCH_HOST, "port": OPENSEARCH_PORT}],
    http_compress=True,
    use_ssl=False,  # Set to True in production with proper certs
    verify_certs=False,
    ssl_assert_hostname=False,
    ssl_show_warn=False,
)


# Pydantic models
class LogEntry(BaseModel):
    """Log entry model"""
    timestamp: Optional[str] = Field(
        default_factory=lambda: datetime.utcnow().isoformat()
    )
    level: str = Field(..., description="Log level (INFO, WARN, ERROR, DEBUG)")
    message: str = Field(..., description="Log message")
    service: Optional[str] = Field(None, description="Service name")
    host: Optional[str] = Field(None, description="Hostname")
    metadata: Optional[Dict[str, Any]] = Field(
        default_factory=dict, 
        description="Additional metadata"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "level": "INFO",
                "message": "User login successful",
                "service": "auth-service",
                "host": "web-server-01",
                "metadata": {"user_id": "12345", "ip": "192.168.1.1"}
            }
        }


class SearchQuery(BaseModel):
    """Search query model"""
    query: Optional[str] = Field(None, description="Search text")
    level: Optional[str] = Field(None, description="Filter by log level")
    service: Optional[str] = Field(None, description="Filter by service name")
    start_time: Optional[str] = Field(
        None, 
        description="Start timestamp (ISO format)"
    )
    end_time: Optional[str] = Field(
        None, 
        description="End timestamp (ISO format)"
    )
    size: int = Field(
        100, 
        ge=1, 
        le=10000, 
        description="Number of results to return"
    )
    from_: int = Field(
        0, 
        ge=0, 
        description="Offset for pagination", 
        alias="from"
    )

    class Config:
        populate_by_name = True


@app.on_event("startup")
async def startup_event():
    """Initialize OpenSearch index on startup"""
    try:
        if not opensearch_client.indices.exists(index=INDEX_NAME):
            # Create index with mappings
            index_body = {
                "settings": {
                    "number_of_shards": 1,
                    "number_of_replicas": 0
                },
                "mappings": {
                    "properties": {
                        "timestamp": {"type": "date"},
                        "level": {"type": "keyword"},
                        "message": {"type": "text"},
                        "service": {"type": "keyword"},
                        "host": {"type": "keyword"},
                        "metadata": {"type": "object", "enabled": True}
                    }
                }
            }
            opensearch_client.indices.create(index=INDEX_NAME, body=index_body)
            logger.info(f"Created index: {INDEX_NAME}")
        else:
            logger.info(f"Index {INDEX_NAME} already exists")
    except Exception as e:
        logger.error(f"Error initializing OpenSearch: {str(e)}")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "Log Indexer API",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "ingest": "POST /logs",
            "bulk_ingest": "POST /logs/bulk",
            "search": "POST /logs/search",
            "get": "GET /logs/{id}",
            "delete": "DELETE /logs/{id}"
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    try:
        # Check OpenSearch connection
        health = opensearch_client.cluster.health()
        return {
            "status": "healthy",
            "opensearch": {
                "connected": True,
                "cluster_status": health.get("status")
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "unhealthy",
                "error": str(e)
            }
        )


@app.post("/logs", status_code=status.HTTP_201_CREATED, tags=["Logs"])
async def ingest_log(log_entry: LogEntry):
    """Ingest a single log entry"""
    try:
        response = opensearch_client.index(
            index=INDEX_NAME,
            body=log_entry.model_dump(),
            refresh=True
        )
        return {
            "id": response["_id"],
            "status": "indexed",
            "index": INDEX_NAME
        }
    except OpenSearchException as e:
        logger.error(f"Failed to index log: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to index log: {str(e)}"
        )


@app.post("/logs/bulk", status_code=status.HTTP_201_CREATED, tags=["Logs"])
async def ingest_logs_bulk(log_entries: List[LogEntry]):
    """Ingest multiple log entries in bulk"""
    try:
        bulk_body = []
        for log_entry in log_entries:
            bulk_body.append({"index": {"_index": INDEX_NAME}})
            bulk_body.append(log_entry.model_dump())
        
        response = opensearch_client.bulk(body=bulk_body, refresh=True)
        
        if response.get("errors"):
            logger.warning("Some logs failed to index")
        
        return {
            "indexed": len(log_entries),
            "errors": response.get("errors", False)
        }
    except OpenSearchException as e:
        logger.error(f"Bulk indexing failed: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Bulk indexing failed: {str(e)}"
        )


@app.post("/logs/search", tags=["Logs"])
async def search_logs(search_query: SearchQuery):
    """Search logs with filters"""
    try:
        # Build query
        must_conditions = []
        
        if search_query.query:
            must_conditions.append({
                "match": {"message": search_query.query}
            })
        
        if search_query.level:
            must_conditions.append({
                "term": {"level": search_query.level}
            })
        
        if search_query.service:
            must_conditions.append({
                "term": {"service": search_query.service}
            })
        
        if search_query.start_time or search_query.end_time:
            range_query = {"range": {"timestamp": {}}}
            if search_query.start_time:
                range_query["range"]["timestamp"]["gte"] = search_query.start_time
            if search_query.end_time:
                range_query["range"]["timestamp"]["lte"] = search_query.end_time
            must_conditions.append(range_query)
        
        query_body = {
            "query": {
                "bool": {
                    "must": must_conditions if must_conditions else [{"match_all": {}}]
                }
            },
            "sort": [{"timestamp": {"order": "desc"}}],
            "size": search_query.size,
            "from": search_query.from_
        }
        
        response = opensearch_client.search(index=INDEX_NAME, body=query_body)
        
        hits = response["hits"]["hits"]
        results = [
            {
                "id": hit["_id"],
                "score": hit["_score"],
                **hit["_source"]
            }
            for hit in hits
        ]
        
        return {
            "total": response["hits"]["total"]["value"],
            "results": results
        }
    except OpenSearchException as e:
        logger.error(f"Search failed: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Search failed: {str(e)}"
        )


@app.get("/logs/{log_id}", tags=["Logs"])
async def get_log(log_id: str):
    """Retrieve a specific log entry by ID"""
    try:
        response = opensearch_client.get(index=INDEX_NAME, id=log_id)
        return {
            "id": response["_id"],
            **response["_source"]
        }
    except OpenSearchException as e:
        if e.status_code == 404:
            raise HTTPException(status_code=404, detail="Log not found")
        logger.error(f"Failed to retrieve log: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to retrieve log: {str(e)}"
        )


@app.delete("/logs/{log_id}", tags=["Logs"])
async def delete_log(log_id: str):
    """Delete a specific log entry"""
    try:
        response = opensearch_client.delete(
            index=INDEX_NAME, 
            id=log_id, 
            refresh=True
        )
        return {
            "id": log_id,
            "status": "deleted"
        }
    except OpenSearchException as e:
        if e.status_code == 404:
            raise HTTPException(status_code=404, detail="Log not found")
        logger.error(f"Failed to delete log: {str(e)}")
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to delete log: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)