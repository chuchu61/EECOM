#!/bin/bash
echo "🔧 Quick Backend Start..."
docker-compose up -d backend mongodb && echo "✅ Backend ready: http://localhost:5000" 