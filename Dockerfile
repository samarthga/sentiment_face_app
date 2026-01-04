# Build stage for Flutter web
FROM debian:bookworm-slim AS flutter-build

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
WORKDIR /flutter
RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz \
    && tar xf flutter.tar.xz \
    && rm flutter.tar.xz

ENV PATH="/flutter/flutter/bin:$PATH"

# Build Flutter web app
WORKDIR /app/flutter_app
COPY flutter_app/ .
RUN flutter pub get && flutter build web --release --web-renderer html

# Production stage
FROM python:3.11.7-slim

WORKDIR /app

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ .

# Copy Flutter build from previous stage
COPY --from=flutter-build /app/flutter_app/build/web /app/static

# Expose port
EXPOSE 10000

# Start the server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]
