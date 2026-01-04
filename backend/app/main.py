"""
Sentiment Face API - Backend server for aggregating internet sentiment.
"""
import logging
import os
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.api.routes import sentiment, health
from app.core.config import settings
from app.core.scheduler import start_scheduler, stop_scheduler

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    start_scheduler()
    yield
    # Shutdown
    stop_scheduler()


app = FastAPI(
    title="Sentiment Face API",
    description="Aggregate sentiment from internet discussion boards",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, tags=["Health"])
app.include_router(sentiment.router, prefix="/api/v1/sentiment", tags=["Sentiment"])


@app.get("/api")
async def api_root():
    """API root endpoint."""
    return {
        "name": "Sentiment Face API",
        "version": "1.0.0",
        "status": "running",
    }


# Serve Flutter web static files in production
STATIC_DIR = Path(__file__).parent.parent / "static"

if STATIC_DIR.exists():
    # Mount static files (JS, CSS, assets)
    app.mount("/assets", StaticFiles(directory=STATIC_DIR / "assets"), name="assets")
    app.mount("/icons", StaticFiles(directory=STATIC_DIR / "icons"), name="icons")

    # Serve Flutter web app files
    @app.get("/flutter_bootstrap.js")
    async def flutter_bootstrap():
        return FileResponse(STATIC_DIR / "flutter_bootstrap.js", media_type="application/javascript")

    @app.get("/flutter.js")
    async def flutter_js():
        return FileResponse(STATIC_DIR / "flutter.js", media_type="application/javascript")

    @app.get("/main.dart.js")
    async def main_dart_js():
        js_file = STATIC_DIR / "main.dart.js"
        if js_file.exists():
            return FileResponse(js_file, media_type="application/javascript")
        return FileResponse(STATIC_DIR / "index.html")

    @app.get("/flutter_service_worker.js")
    async def service_worker():
        return FileResponse(STATIC_DIR / "flutter_service_worker.js", media_type="application/javascript")

    @app.get("/manifest.json")
    async def manifest():
        return FileResponse(STATIC_DIR / "manifest.json", media_type="application/json")

    @app.get("/favicon.png")
    async def favicon():
        return FileResponse(STATIC_DIR / "favicon.png", media_type="image/png")

    @app.get("/version.json")
    async def version():
        version_file = STATIC_DIR / "version.json"
        if version_file.exists():
            return FileResponse(version_file, media_type="application/json")
        return {"version": "1.0.0"}

    # Root route serves index.html
    @app.get("/")
    async def serve_index():
        return FileResponse(STATIC_DIR / "index.html")

    # Catch-all route for Flutter client-side routing
    @app.get("/{path:path}")
    async def serve_spa(path: str):
        # Don't intercept API, health, or static file routes
        if path.startswith(("api", "health", "assets", "icons")):
            # Let FastAPI handle these via their registered routes
            from fastapi import HTTPException
            raise HTTPException(status_code=404, detail="Not found")

        # Check if it's a real file in static directory
        file_path = STATIC_DIR / path
        if file_path.exists() and file_path.is_file():
            return FileResponse(file_path)

        # Otherwise serve index.html for client-side routing
        return FileResponse(STATIC_DIR / "index.html")
else:
    @app.get("/")
    async def root():
        """Root endpoint when no static files are present."""
        return {
            "name": "Sentiment Face API",
            "version": "1.0.0",
            "status": "running",
            "note": "Frontend not deployed. Access API at /api/v1/sentiment"
        }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
