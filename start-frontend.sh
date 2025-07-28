#!/bin/bash

echo "🌐 Starting Frontend only..."

# Kiểm tra xem Docker có chạy không
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Dừng frontend container cũ nếu có
echo "🔄 Stopping existing frontend container..."
docker-compose stop frontend
docker-compose rm -f frontend

# Khởi động frontend
echo "🏗️  Starting Frontend..."
docker-compose up -d frontend

# Đợi frontend khởi động
echo "⏳ Waiting for frontend to start..."
sleep 8

# Kiểm tra trạng thái
echo "📊 Checking frontend status..."
docker-compose ps frontend

# Hiển thị thông tin truy cập
echo ""
echo "✅ Frontend is ready!"
echo "🌐 Frontend: http://localhost:3000"
echo "🌐 Frontend Dev: http://localhost:3030"
echo ""
echo "🔍 Useful commands:"
echo "   docker-compose logs -f frontend   # View frontend logs"
echo "   docker-compose stop frontend     # Stop frontend"
echo ""
echo "💡 Note: Make sure backend is running on the other WSL!" 