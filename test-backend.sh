#!/bin/bash

# Script test backend API
echo "🧪 Testing Backend API..."

# Backend URL
BACKEND_URL="http://localhost:5000"

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local description=$2
    
    echo "📡 Testing $description: $BACKEND_URL$endpoint"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL$endpoint")
    
    if [ "$response" == "200" ]; then
        echo "✅ $description: OK ($response)"
        curl -s "$BACKEND_URL$endpoint" | python3 -m json.tool 2>/dev/null || curl -s "$BACKEND_URL$endpoint"
        echo ""
    else
        echo "❌ $description: FAILED ($response)"
    fi
}

# Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
for i in {1..30}; do
    if curl -s "$BACKEND_URL" > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Backend not responding after 30 seconds"
        echo "💡 Check logs: docker-compose logs backend"
        exit 1
    fi
    
    echo "⏳ Attempt $i/30 - waiting..."
    sleep 1
done

echo ""
echo "🚀 Running API Tests..."
echo "========================"

# Test endpoints
test_endpoint "/" "Root endpoint"
test_endpoint "/health" "Health check"
test_endpoint "/api" "API info"

echo ""
echo "🎉 Backend testing completed!"
echo "🌐 You can now open: $BACKEND_URL in your browser" 