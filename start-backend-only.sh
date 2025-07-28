#!/bin/bash

echo "🚀 Starting Backend + MongoDB only..."

# Kiểm tra xem Docker có chạy không
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Dừng các container cũ nếu có
echo "🔄 Stopping existing containers..."
docker-compose down

# Khởi động backend và MongoDB
echo "🏗️  Starting Backend + MongoDB..."
docker-compose up -d backend mongodb

# Đợi services khởi động
echo "⏳ Waiting for services to start..."
sleep 8

# Kiểm tra trạng thái
echo "📊 Checking services status..."
docker-compose ps

# Hiển thị thông tin truy cập
echo ""
echo "✅ Backend services are ready!"
echo "🔧 Backend API: http://localhost:5000"
echo "🗄️  MongoDB: localhost:27017"
echo ""
echo "📝 Test login:"
echo "   curl -X POST http://localhost:5000/auth/login -H \"Content-Type: application/json\" -d '{\"email\": \"admin@ecom.com\", \"password\": \"eecom\"}'"
echo ""
echo "🔍 Useful commands:"
echo "   docker-compose logs -f backend mongodb   # View logs"
echo "   docker-compose down                      # Stop services" 