#!/bin/bash
# Build script for Render deployment

set -e

echo "=== Building Sentiment Face App for Production ==="

# Install Python dependencies
echo "Installing Python dependencies..."
cd backend
pip install -r requirements.txt

# Setup Flutter
echo "Setting up Flutter..."
cd ../flutter_app

# Check if Flutter is available, otherwise download it
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found, downloading..."
    curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz -o flutter.tar.xz
    tar xf flutter.tar.xz
    export PATH="$PATH:$(pwd)/flutter/bin"
    rm flutter.tar.xz
fi

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build Flutter web
echo "Building Flutter web app..."
flutter build web --release --web-renderer html

# Copy web build to backend static folder
echo "Copying web build to backend..."
rm -rf ../backend/static
cp -r build/web ../backend/static

echo "=== Build complete! ==="
echo "To start the server, run: cd backend && uvicorn app.main:app --host 0.0.0.0 --port 8000"
