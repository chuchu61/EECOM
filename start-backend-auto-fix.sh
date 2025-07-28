#!/bin/bash

# Script tự động khắc phục và khởi động backend
echo "🤖 AUTO-FIX & START BACKEND"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════${NC}"
}

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

# 1. MongoDB Fix
print_header "PHASE 1: FIXING MONGODB"
print_step "Chạy MongoDB fix script..."

# Cho phép thực thi và chạy
chmod +x fix-mongodb.sh
if ./fix-mongodb.sh; then
    print_success "MongoDB đã được sửa thành công!"
else
    print_error "MongoDB fix failed!"
    print_warning "Thử khởi động backend native mode thay thế..."
    
    print_header "FALLBACK: NATIVE PYTHON MODE"
    chmod +x start-backend-native.sh
    if ./start-backend-native.sh; then
        print_success "Backend started in native mode!"
        exit 0
    else
        print_error "Tất cả methods đều failed. Cần support!"
        exit 1
    fi
fi

# 2. Backend Start
print_header "PHASE 2: STARTING BACKEND"

# Đợi MongoDB ổn định
print_step "Đợi MongoDB ổn định..."
sleep 5

# Thử Docker simple method trước
print_step "Thử Docker simple method..."
chmod +x start-backend-simple.sh

# Tạm thời redirect để kiểm tra output
if timeout 60 ./start-backend-simple.sh > /tmp/backend_start.log 2>&1; then
    print_success "Backend started với Docker simple method!"
    
    # Hiển thị output cuối
    tail -20 /tmp/backend_start.log
    
elif [ $? -eq 124 ]; then
    print_warning "Docker method timeout, kiểm tra container..."
    
    # Kiểm tra container có chạy không
    if docker ps | grep -q ecom_backend; then
        print_success "Backend container đang chạy!"
    else
        print_warning "Backend container không chạy, thử native method..."
        
        print_header "FALLBACK: NATIVE PYTHON"
        chmod +x start-backend-native.sh
        ./start-backend-native.sh &
        NATIVE_PID=$!
        
        # Đợi backend native start
        sleep 10
        
        if curl -s http://localhost:5000 > /dev/null 2>&1; then
            print_success "Backend started với native method!"
        else
            print_error "Native method cũng failed"
            kill $NATIVE_PID 2>/dev/null
            exit 1
        fi
    fi
    
else
    print_error "Docker simple method failed"
    print_step "Kiểm tra logs..."
    cat /tmp/backend_start.log | tail -20
    
    print_warning "Thử native method..."
    print_header "FALLBACK: NATIVE PYTHON"
    chmod +x start-backend-native.sh
    ./start-backend-native.sh &
    NATIVE_PID=$!
    
    sleep 10
    if curl -s http://localhost:5000 > /dev/null 2>&1; then
        print_success "Backend started với native method!"
    else
        print_error "Tất cả methods failed!"
        kill $NATIVE_PID 2>/dev/null
        exit 1
    fi
fi

# 3. Final Testing
print_header "PHASE 3: FINAL VERIFICATION"

print_step "Testing API endpoints..."

# Test endpoints
endpoints=("/" "/health" "/api")
for endpoint in "${endpoints[@]}"; do
    print_step "Testing http://localhost:5000$endpoint"
    
    response=$(curl -s -w "%{http_code}" http://localhost:5000$endpoint)
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" == "200" ]; then
        print_success "Endpoint $endpoint: OK"
        if command -v python3 &> /dev/null; then
            echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
        else
            echo "$body"
        fi
    else
        print_error "Endpoint $endpoint: FAILED ($http_code)"
    fi
    echo ""
done

# 4. System Status
print_header "SYSTEM STATUS"

echo "🐳 Docker Containers:"
docker ps | grep ecom || echo "Không có container nào"

echo ""
echo "🔌 Port Status:"
netstat -tulpn 2>/dev/null | grep ":5000\|:27017" || ss -tulpn 2>/dev/null | grep ":5000\|:27017" || echo "Không detect được port"

echo ""
echo "📊 Services Health:"
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo "✅ Backend: HEALTHY"
else
    echo "❌ Backend: DOWN"
fi

if docker ps | grep -q ecom_mongodb; then
    echo "✅ MongoDB: RUNNING"
elif pgrep -f mongod > /dev/null; then
    echo "✅ MongoDB: RUNNING (native)"
else
    echo "❌ MongoDB: DOWN"
fi

# 5. Final Instructions
print_header "SUCCESS! BACKEND IS RUNNING"

echo -e "${GREEN}🎉 Backend khởi động thành công!${NC}"
echo ""
echo "🌐 Truy cập backend:"
echo "   • Homepage: ${CYAN}http://localhost:5000${NC}"
echo "   • Health Check: ${CYAN}http://localhost:5000/health${NC}"
echo "   • API Docs: ${CYAN}http://localhost:5000/api${NC}"
echo ""
echo "📋 Useful Commands:"
echo "   • Xem logs backend: ${YELLOW}docker logs ecom_backend${NC}"
echo "   • Xem logs MongoDB: ${YELLOW}docker logs ecom_mongodb${NC}"
echo "   • Restart backend: ${YELLOW}docker restart ecom_backend${NC}"
echo "   • Stop all: ${YELLOW}docker stop ecom_backend ecom_mongodb${NC}"
echo ""
echo "🛠️ Troubleshooting:"
echo "   • Debug: ${YELLOW}./debug-backend.sh${NC}"
echo "   • MongoDB fix: ${YELLOW}./fix-mongodb.sh${NC}"
echo "   • Manual start: ${YELLOW}./start-backend-simple.sh${NC}"
echo ""
echo -e "${GREEN}✨ Mở browser và truy cập: http://localhost:5000 ✨${NC}"

# Cleanup temp files
rm -f /tmp/backend_start.log 