#!/bin/bash

# Script khắc phục MongoDB issues
echo "🛠️ KHẮC PHỤC MONGODB ISSUES"
echo "============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}🔸 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# 1. Kiểm tra Docker
print_step "Kiểm tra Docker daemon..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker không chạy!"
    echo "Khởi động Docker:"
    echo "sudo systemctl start docker"
    echo "sudo systemctl enable docker"
    exit 1
fi
print_success "Docker OK"

# 2. Dọn dẹp MongoDB containers cũ
print_step "Dọn dẹp MongoDB containers cũ..."
docker stop ecom_mongodb mongodb mongo 2>/dev/null || true
docker rm ecom_mongodb mongodb mongo 2>/dev/null || true
print_success "Containers cũ đã được dọn dẹp"

# 3. Kiểm tra port 27017
print_step "Kiểm tra port 27017..."
if netstat -tulpn 2>/dev/null | grep -q ":27017" || ss -tulpn 2>/dev/null | grep -q ":27017"; then
    print_warning "Port 27017 đang được sử dụng"
    echo "Processes using port 27017:"
    lsof -i :27017 2>/dev/null || ss -tulpn | grep :27017
    
    echo -e "\n${YELLOW}Trying to kill processes...${NC}"
    # Kill processes using port 27017
    sudo fuser -k 27017/tcp 2>/dev/null || true
    sleep 2
    
    if netstat -tulpn 2>/dev/null | grep -q ":27017" || ss -tulpn 2>/dev/null | grep -q ":27017"; then
        print_warning "Port vẫn bị chiếm, sẽ thử port khác"
        MONGO_PORT=27018
    else
        print_success "Port 27017 đã được giải phóng"
        MONGO_PORT=27017
    fi
else
    print_success "Port 27017 available"
    MONGO_PORT=27017
fi

# 4. Pull MongoDB image
print_step "Pull MongoDB image..."
docker pull mongo:5.0
if [ $? -eq 0 ]; then
    print_success "MongoDB image pulled"
else
    print_error "Failed to pull MongoDB image"
    print_warning "Thử với image cũ hơn..."
    docker pull mongo:4.4
    if [ $? -eq 0 ]; then
        MONGO_IMAGE="mongo:4.4"
        print_success "MongoDB 4.4 image pulled"
    else
        print_error "Không thể pull MongoDB image"
        exit 1
    fi
fi

MONGO_IMAGE=${MONGO_IMAGE:-"mongo:5.0"}

# 5. Tạo network
print_step "Tạo Docker network..."
docker network create ecom_network 2>/dev/null || true
print_success "Network ready"

# 6. Khởi động MongoDB với các config khác nhau
print_step "Khởi động MongoDB..."

# Thử config đơn giản nhất trước
echo "Thử config đơn giản..."
docker run -d \
  --name ecom_mongodb \
  --network ecom_network \
  -p ${MONGO_PORT}:27017 \
  --restart unless-stopped \
  ${MONGO_IMAGE} \
  mongod --noauth --bind_ip_all

sleep 5

# Kiểm tra MongoDB có chạy không
if docker ps | grep -q ecom_mongodb; then
    print_success "MongoDB container started"
    
    # Test connection
    print_step "Testing MongoDB connection..."
    for i in {1..20}; do
        if docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            print_success "MongoDB connection OK!"
            break
        elif docker exec ecom_mongodb mongo --eval "db.adminCommand('ping')" &>/dev/null; then
            print_success "MongoDB connection OK! (legacy mongo client)"
            break
        fi
        
        if [ $i -eq 20 ]; then
            print_warning "MongoDB connection test failed, but container is running"
            break
        fi
        
        echo "⏳ Testing connection... ($i/20)"
        sleep 2
    done
    
else
    print_error "MongoDB container failed to start"
    echo -e "\n${YELLOW}Trying alternative configurations...${NC}"
    
    # Thử config 2: Với volume mount
    print_step "Thử với volume mount..."
    docker run -d \
      --name ecom_mongodb \
      --network ecom_network \
      -p ${MONGO_PORT}:27017 \
      -v mongodb_data:/data/db \
      --restart unless-stopped \
      ${MONGO_IMAGE}
    
    sleep 5
    
    if docker ps | grep -q ecom_mongodb; then
        print_success "MongoDB started with volume"
    else
        # Thử config 3: Minimal config
        print_step "Thử minimal config..."
        docker run -d \
          --name ecom_mongodb \
          -p ${MONGO_PORT}:27017 \
          ${MONGO_IMAGE} \
          --nojournal --smallfiles --noauth
        
        sleep 5
        
        if docker ps | grep -q ecom_mongodb; then
            print_success "MongoDB started with minimal config"
        else
            print_error "Tất cả MongoDB configs đều failed"
            echo -e "\n${YELLOW}Checking logs...${NC}"
            docker logs ecom_mongodb
            exit 1
        fi
    fi
fi

# 7. Final verification
print_step "Final verification..."
echo "Container status:"
docker ps | grep ecom_mongodb

echo -e "\nContainer logs (last 10 lines):"
docker logs ecom_mongodb --tail=10

echo -e "\nMongoDB info:"
echo "📡 Port: ${MONGO_PORT}"
echo "🐳 Image: ${MONGO_IMAGE}"
echo "🔗 URI: mongodb://localhost:${MONGO_PORT}/exp_ecom_db"

# 8. Update .env if port changed
if [ "${MONGO_PORT}" != "27017" ]; then
    print_step "Updating .env file..."
    if [ -f "backend/.env" ]; then
        sed -i "s/mongodb:\/\/localhost:27017/mongodb:\/\/localhost:${MONGO_PORT}/g" backend/.env
        print_success ".env updated with new port"
    fi
fi

# 9. Test basic MongoDB operations
print_step "Testing basic MongoDB operations..."
if docker exec ecom_mongodb mongosh --eval "
    use exp_ecom_db;
    db.test.insertOne({test: 'connection', timestamp: new Date()});
    db.test.findOne();
" &>/dev/null; then
    print_success "MongoDB operations test passed"
elif docker exec ecom_mongodb mongo --eval "
    use exp_ecom_db;
    db.test.insertOne({test: 'connection', timestamp: new Date()});
    db.test.findOne();
" &>/dev/null; then
    print_success "MongoDB operations test passed (legacy client)"
else
    print_warning "MongoDB operations test failed, but container is running"
fi

echo -e "\n${GREEN}🎉 MONGODB SETUP COMPLETED!${NC}"
echo "=================================="
echo "✅ MongoDB container: ecom_mongodb"
echo "✅ Port: ${MONGO_PORT}"
echo "✅ Network: ecom_network"
echo "✅ URI: mongodb://localhost:${MONGO_PORT}/exp_ecom_db"
echo ""
echo "📋 Next steps:"
echo "   1. Test connection: docker exec ecom_mongodb mongosh"
echo "   2. Start backend: ./start-backend-simple.sh"
echo "   3. Or use native: ./start-backend-native.sh"
echo ""
echo "🛑 To stop: docker stop ecom_mongodb" 