"""Health check endpoints."""
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """Check if the API is running."""
    return {"status": "healthy"}


@router.get("/ready")
async def readiness_check():
    """Check if the API is ready to serve requests."""
    # TODO: Add database and model checks
    return {"status": "ready"}
