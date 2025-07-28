#!/bin/bash

echo "🚀 RESTARTING FRONTEND WITH FIXED CONFIG"
echo "========================================"

# Kill any existing frontend process on port 3000
echo "🛑 Stopping existing frontend..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Wait a moment
sleep 2

# Start frontend
echo "🚀 Starting frontend..."
cd frontend

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start development server
echo "🌐 Starting development server on port 3000..."
PORT=3000 npm run dev

