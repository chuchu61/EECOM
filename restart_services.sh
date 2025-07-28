#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🔄 Restarting ecom services..."

# Check if virtual environment exists
if [ ! -d "backend/venv_production" ]; then
    print_error "❌ Virtual environment not found. Please run ./setup_and_run.sh first"
    exit 1
fi

# Check if .env exists
if [ ! -f "backend/.env" ]; then
    print_error "❌ Configuration file not found. Please run ./setup_and_run.sh first"
    exit 1
fi

# Stop any existing services
print_status "🛑 Stopping existing services..."
pkill -f "python.*start_backend" || true
docker stop ecom_mongodb 2>/dev/null || true

# Start MongoDB container
print_status "🍃 Starting MongoDB..."
if docker ps -a | grep -q ecom_mongodb; then
    docker start ecom_mongodb
else
    docker run -d \
      --name ecom_mongodb \
      -p 27017:27017 \
      -v mongodb_data:/data/db \
      -e MONGO_INITDB_DATABASE=exp_ecom_db \
      --restart unless-stopped \
      mongo:latest
fi

# Wait for MongoDB
print_status "⏳ Waiting for MongoDB..."
sleep 5

# Check MongoDB health
for i in {1..15}; do
    if docker exec ecom_mongodb mongosh --eval "db.runCommand('ping')" >/dev/null 2>&1; then
        print_success "✅ MongoDB is ready"
        break
    fi
    if [ $i -eq 15 ]; then
        print_error "❌ MongoDB failed to start"
        exit 1
    fi
    sleep 2
done

# Start backend
print_status "🚀 Starting backend..."
cd backend
source venv_production/bin/activate

if [ -f "start_backend_safe.py" ]; then
    python start_backend_safe.py
else
    python start_backend.py
fi 