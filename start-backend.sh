#!/bin/bash

echo "🔧 Starting Backend + MongoDB only..."

# Kiểm tra xem Docker có chạy không
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Dừng backend và mongodb container cũ nếu có
echo "🔄 Stopping existing backend containers..."
docker-compose stop backend mongodb
docker-compose rm -f backend mongodb

# Khởi động backend và MongoDB
echo "🏗️  Starting Backend + MongoDB..."
docker-compose up -d backend mongodb

# Đợi services khởi động
echo "⏳ Waiting for services to start..."
sleep 10

# Kiểm tra trạng thái
echo "📊 Checking services status..."
docker-compose ps backend mongodb

# Hiển thị thông tin truy cập
echo ""
echo "✅ Backend services are ready!"
echo "🔧 Backend API: http://localhost:5000"
echo "🗄️  MongoDB: localhost:27017"
echo ""
echo "📝 Available accounts:"
echo "   👑 Admin: admin@ecom.com / eecom"
echo "   👤 User: user@example.com / user123"
echo "   ✏️  Editor: editor@example.com / editor123"
echo ""
echo "🔍 Useful commands:"
echo "   docker-compose logs -f backend mongodb   # View logs"
echo "   docker-compose stop backend mongodb     # Stop services"
echo ""
echo "💡 Note: Frontend should be running on the other WSL!" 