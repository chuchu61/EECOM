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

print_status "🛑 Stopping all ecom services..."

# Stop backend (if running in background)
print_status "🔴 Stopping backend server..."
pkill -f "python.*start_backend" || true
pkill -f "flask" || true

# Stop MongoDB container
print_status "🍃 Stopping MongoDB container..."
docker stop ecom_mongodb 2>/dev/null || true

# Kill any processes using our ports
print_status "🔌 Freeing up ports..."
lsof -ti:5000 | xargs kill -9 2>/dev/null || true
lsof -ti:27017 | xargs kill -9 2>/dev/null || true

print_success "✅ All services stopped successfully!"

echo ""
echo "📋 Services stopped:"
echo "  🔴 Backend server"
echo "  🍃 MongoDB container"
echo ""
echo "🔄 To restart services, run: ./setup_and_run.sh"
echo "🗑️  To completely remove: ./cleanup_all.sh" 