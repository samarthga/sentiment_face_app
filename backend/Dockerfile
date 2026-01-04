FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/
COPY data/ ./data/

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Railway uses PORT env variable
ENV PORT=8000
EXPOSE $PORT

# Run the application with dynamic port
CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT
