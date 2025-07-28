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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_warning "⚠️  This will completely remove all ecom containers, volumes, and virtual environments!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

print_status "🧹 Performing complete cleanup..."

# Stop all processes
print_status "🛑 Stopping all services..."
pkill -f "python.*start_backend" || true
pkill -f "flask" || true

# Remove containers
print_status "🗑️  Removing containers..."
docker stop ecom_backend ecom_mongodb ecom_frontend 2>/dev/null || true
docker rm ecom_backend ecom_mongodb ecom_frontend 2>/dev/null || true

# Remove volumes
print_status "💾 Removing volumes..."
docker volume rm mongodb_data ecom_mongodb_data ecom_mongodb_config backend_python_modules 2>/dev/null || true

# Remove networks
print_status "🌐 Removing networks..."
docker network rm ecom_network 2>/dev/null || true

# Remove virtual environments
print_status "🐍 Removing virtual environments..."
cd backend 2>/dev/null || true
rm -rf venv venv_clean venv_new venv_production .venv 2>/dev/null || true

# Remove generated files
print_status "📁 Removing generated files..."
rm -f backend/start_backend_safe.py 2>/dev/null || true
rm -f backend/.env 2>/dev/null || true

# Free up ports
print_status "🔌 Freeing up ports..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
lsof -ti:5000 | xargs kill -9 2>/dev/null || true
lsof -ti:27017 | xargs kill -9 2>/dev/null || true

# Docker system cleanup
print_status "🧽 Running Docker system cleanup..."
docker system prune -f || true

print_success "✅ Complete cleanup finished!"

echo ""
echo "📋 Removed:"
echo "  🗑️  All ecom containers"
echo "  💾 All related volumes"
echo "  🌐 All related networks"
echo "  🐍 All virtual environments"
echo "  📁 Generated configuration files"
echo ""
echo "🚀 To setup and run again: ./setup_and_run.sh" 