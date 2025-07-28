#!/bin/bash

# Script khởi động backend đơn giản (không dùng docker-compose)
echo "🚀 KHỞI ĐỘNG BACKEND - SIMPLE MODE"
echo "=================================="

# Function để hiển thị status
print_step() {
    echo -e "\n🔸 $1"
}

print_success() {
    echo -e "✅ $1"
}

print_error() {
    echo -e "❌ $1"
}

# Dọn dẹp containers cũ
print_step "Dọn dẹp containers cũ..."
docker stop ecom_backend ecom_mongodb 2>/dev/null || true
docker rm ecom_backend ecom_mongodb 2>/dev/null || true

# Tạo network
print_step "Tạo Docker network..."
docker network create ecom_network 2>/dev/null || true
print_success "Network ready"

# Khởi động MongoDB trước
print_step "Khởi động MongoDB..."
docker run -d \
  --name ecom_mongodb \
  --network ecom_network \
  -p 27017:27017 \
  -e MONGO_INITDB_DATABASE=exp_ecom_db \
  mongo:5.0

if [ $? -eq 0 ]; then
    print_success "MongoDB started"
else
    print_error "MongoDB failed to start"
    exit 1
fi

# Đợi MongoDB ready
print_step "Đợi MongoDB sẵn sàng..."
for i in {1..30}; do
    if docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        print_success "MongoDB is ready!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        print_error "MongoDB timeout"
        exit 1
    fi
    
    echo "⏳ Waiting... ($i/30)"
    sleep 2
done

# Build backend image
print_step "Build Backend image..."
cd backend
docker build -t ecom_backend_img .
cd ..

if [ $? -eq 0 ]; then
    print_success "Backend image built"
else
    print_error "Backend build failed"
    exit 1
fi

# Khởi động Backend
print_step "Khởi động Backend..."
docker run -d \
  --name ecom_backend \
  --network ecom_network \
  -p 5000:5000 \
  -e MONGO_URI=mongodb://ecom_mongodb:27017/exp_ecom_db \
  -e JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0 \
  -e FLASK_ENV=development \
  -e PYTHONUNBUFFERED=1 \
  -v "$(pwd)/backend:/app" \
  ecom_backend_img

if [ $? -eq 0 ]; then
    print_success "Backend started"
else
    print_error "Backend failed to start"
    exit 1
fi

# Đợi backend ready
print_step "Đợi Backend sẵn sàng..."
for i in {1..45}; do
    if curl -s http://localhost:5000 &>/dev/null; then
        print_success "Backend is ready!"
        break
    fi
    
    if [ $i -eq 45 ]; then
        print_error "Backend timeout"
        echo "Checking logs..."
        docker logs ecom_backend
        exit 1
    fi
    
    echo "⏳ Waiting... ($i/45)"
    sleep 2
done

# Test API
print_step "Testing API endpoints..."

echo "📡 Testing http://localhost:5000"
curl -s http://localhost:5000 | python3 -m json.tool 2>/dev/null || curl -s http://localhost:5000

echo -e "\n📊 Testing http://localhost:5000/health"  
curl -s http://localhost:5000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:5000/health

# Final status
print_step "Kiểm tra containers..."
docker ps | grep ecom

echo -e "\n🎉 BACKEND READY!"
echo "=================================="
echo "🌐 Backend API: http://localhost:5000"
echo "🗄️ MongoDB: localhost:27017"
echo ""
echo "📋 Useful commands:"
echo "   📋 Backend logs: docker logs ecom_backend"
echo "   📋 MongoDB logs: docker logs ecom_mongodb"  
echo "   🔄 Restart backend: docker restart ecom_backend"
echo "   🛑 Stop all: docker stop ecom_backend ecom_mongodb"
echo ""
echo "🌐 Mở trình duyệt: http://localhost:5000" 