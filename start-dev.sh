#!/bin/bash

echo "🚀 Starting ECOM Development Environment..."

# Kiểm tra xem Docker có chạy không
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Dừng các container cũ nếu có
echo "🔄 Stopping existing containers..."
docker-compose down

# Khởi động các services
echo "🏗️  Starting services..."
docker-compose up -d

# Đợi services khởi động
echo "⏳ Waiting for services to start..."
sleep 10

# Kiểm tra trạng thái
echo "📊 Checking services status..."
docker-compose ps

# Hiển thị thông tin truy cập
echo ""
echo "✅ Services are ready!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend API: http://localhost:5000"
echo "🗄️  MongoDB: localhost:27017"
echo ""
echo "📝 Available accounts:"
echo "   👑 Admin: admin@ecom.com / eecom"
echo "   👤 User: user@example.com / user123"
echo "   ✏️  Editor: editor@example.com / editor123"
echo ""
echo "🔍 Useful commands:"
echo "   docker-compose logs -f backend    # View backend logs"
echo "   docker-compose logs -f frontend   # View frontend logs"
echo "   docker-compose down               # Stop all services" 