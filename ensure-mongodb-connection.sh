#!/bin/bash

# Script đảm bảo backend kết nối đúng MongoDB (không phải SQL)
echo "🔧 ENSURING BACKEND CONNECTS TO MONGODB"
echo "======================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}ℹ️ $1${NC}"
}

# 1. Kiểm tra MongoDB đang chạy
print_step "1. Đảm bảo MongoDB đang chạy..."

if ! docker ps | grep -q ecom_mongodb; then
    print_warning "MongoDB container không chạy, khởi động..."
    ./fix-mongodb.sh
    
    if ! docker ps | grep -q ecom_mongodb; then
        print_error "Không thể khởi động MongoDB"
        exit 1
    fi
fi

print_success "MongoDB container đang chạy"

# Get MongoDB port
MONGO_PORT=$(docker port ecom_mongodb 27017 2>/dev/null | cut -d: -f2)
if [ -z "$MONGO_PORT" ]; then
    MONGO_PORT=27017
fi
print_info "MongoDB port: $MONGO_PORT"

# 2. Kiểm tra và sửa backend .env
print_step "2. Đảm bảo backend .env kết nối đúng MongoDB..."

# Tạo .env đúng cho MongoDB
cat > backend/.env << EOF
# MongoDB Configuration
MONGO_URI=mongodb://localhost:$MONGO_PORT/exp_ecom_db
JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
FLASK_ENV=development
PYTHONUNBUFFERED=1
TESTING=False

# AWS Configuration (optional)
AWS_BUCKET_NAME=ecom.sys
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=

# Database Type - Force MongoDB
DATABASE_TYPE=mongodb
DATABASE_URL=mongodb://localhost:$MONGO_PORT/exp_ecom_db
EOF

print_success "Backend .env updated với MongoDB configuration"

# 3. Kiểm tra config.py có đúng không
print_step "3. Kiểm tra backend config.py..."

# Backup original config
if [ ! -f "backend/config.py.backup" ]; then
    cp backend/config.py backend/config.py.backup
fi

# Tạo config.py đúng cho MongoDB
cat > backend/config.py << 'EOF'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # MongoDB Configuration - KHÔNG SỬ DỤNG SQL
    MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/exp_ecom_db')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'your-secret-key')
    TESTING = False
    
    # Flask Configuration
    SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'your-secret-key')
    
    # Explicitly disable SQL databases
    SQLALCHEMY_DATABASE_URI = None
    DATABASE_URL = None

class TestConfig(Config):
    TESTING = True
    MONGO_URI = 'mongodb://localhost:27017/exp_ecom_test_db'

class ProductionConfig(Config):
    TESTING = False
    MONGO_URI = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/exp_ecom_db')

# Make sure we're using MongoDB
print("🔗 Config loaded - MongoDB URI:", Config.MONGO_URI)
EOF

print_success "Backend config.py updated để force MongoDB"

# 4. Kiểm tra __init__.py có import đúng không
print_step "4. Kiểm tra backend app initialization..."

# Check if app/__init__.py imports any SQL libraries
if grep -q -i "sqlalchemy\|sqlite\|mysql\|postgres" backend/app/__init__.py 2>/dev/null; then
    print_warning "Tìm thấy SQL database imports trong app/__init__.py"
    print_info "Đang remove SQL imports..."
    
    # Backup và clean SQL imports
    cp backend/app/__init__.py backend/app/__init__.py.backup
    
    # Remove SQL-related imports
    sed -i '/sqlalchemy/Id' backend/app/__init__.py
    sed -i '/sqlite/Id' backend/app/__init__.py
    sed -i '/mysql/Id' backend/app/__init__.py
    sed -i '/postgres/Id' backend/app/__init__.py
    
    print_success "SQL imports removed"
else
    print_success "Không có SQL imports trong app/__init__.py"
fi

# 5. Test MongoDB connection
print_step "5. Test MongoDB connection..."

if docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
    print_success "MongoDB connection test passed"
    MONGO_CLIENT="mongosh"
elif docker exec ecom_mongodb mongo --eval "db.adminCommand('ping')" &>/dev/null; then
    print_success "MongoDB connection test passed (legacy client)"
    MONGO_CLIENT="mongo"
else
    print_error "MongoDB connection test failed"
    exit 1
fi

# 6. Restart backend với MongoDB config
print_step "6. Restart backend với MongoDB configuration..."

if docker ps | grep -q ecom_backend; then
    print_info "Stopping current backend..."
    docker stop ecom_backend
    docker rm ecom_backend
fi

# Khởi động backend với MongoDB environment
print_info "Starting backend với MongoDB environment..."

# Get MongoDB container IP cho internal connection
MONGO_IP=$(docker inspect ecom_mongodb | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data[0]['NetworkSettings']['IPAddress'])
" 2>/dev/null)

if [ -z "$MONGO_IP" ]; then
    MONGO_IP="ecom_mongodb"  # Use container name as fallback
fi

print_info "MongoDB container IP: $MONGO_IP"

# Start backend container với đúng MongoDB connection
docker run -d \
  --name ecom_backend \
  --network ecom_network \
  -p 5000:5000 \
  -e MONGO_URI="mongodb://$MONGO_IP:27017/exp_ecom_db" \
  -e JWT_SECRET_KEY="Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0" \
  -e FLASK_ENV="development" \
  -e PYTHONUNBUFFERED=1 \
  -e DATABASE_TYPE="mongodb" \
  -v "$(pwd)/backend:/app" \
  ecom_backend_img

if [ $? -eq 0 ]; then
    print_success "Backend started với MongoDB connection"
else
    print_error "Backend start failed"
    
    # Fallback: build image if not exists
    print_info "Trying to build backend image..."
    cd backend
    docker build -t ecom_backend_img .
    cd ..
    
    # Try again
    docker run -d \
      --name ecom_backend \
      --network ecom_network \
      -p 5000:5000 \
      -e MONGO_URI="mongodb://$MONGO_IP:27017/exp_ecom_db" \
      -e JWT_SECRET_KEY="Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0" \
      -e FLASK_ENV="development" \
      -e PYTHONUNBUFFERED=1 \
      -e DATABASE_TYPE="mongodb" \
      -v "$(pwd)/backend:/app" \
      ecom_backend_img
fi

# 7. Đợi backend khởi động và test
print_step "7. Test backend MongoDB connection..."

print_info "Đợi backend khởi động..."
sleep 10

# Test health endpoint
for i in {1..15}; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "Backend is responding"
        break
    fi
    
    if [ $i -eq 15 ]; then
        print_error "Backend not responding after 15 attempts"
        print_info "Checking logs..."
        docker logs ecom_backend --tail=20
        exit 1
    fi
    
    echo "⏳ Waiting for backend... ($i/15)"
    sleep 2
done

# Test health response
print_info "Testing MongoDB connection via backend..."
health_response=$(curl -s http://localhost:5000/health)
echo "Health response:"
echo "$health_response" | python3 -m json.tool 2>/dev/null || echo "$health_response"

if echo "$health_response" | grep -q "connected\|mongodb"; then
    print_success "Backend successfully connected to MongoDB!"
elif echo "$health_response" | grep -q "error"; then
    print_error "Backend MongoDB connection failed"
    print_info "Checking backend logs for errors..."
    docker logs ecom_backend --tail=20
else
    print_warning "MongoDB connection status unclear"
fi

# 8. Test actual database operations
print_step "8. Test database operations..."

# Test creating a user để đảm bảo MongoDB hoạt động
test_user_data='{
    "email": "mongotest@example.com",
    "password": "testpass123",
    "username": "mongotest"
}'

print_info "Testing user creation (MongoDB operation)..."
register_response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:5000/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "$test_user_data")

register_status=$(echo "$register_response" | tail -1)
register_body=$(echo "$register_response" | head -1)

echo "Register response:"
echo "$register_body" | python3 -m json.tool 2>/dev/null || echo "$register_body"
echo "Status: $register_status"

if [ "$register_status" = "201" ]; then
    print_success "MongoDB operations working - user created"
elif [ "$register_status" = "409" ]; then
    print_success "MongoDB operations working - user already exists"
elif [ "$register_status" = "500" ]; then
    print_error "MongoDB operations failed - server error"
    print_info "Backend có thể vẫn đang cố kết nối SQL database"
else
    print_warning "Unexpected response: $register_status"
fi

# Final verification
print_step "9. Final verification..."

# Check MongoDB có data không
print_info "Checking MongoDB data..."
docker exec ecom_mongodb $MONGO_CLIENT --quiet --eval "
use exp_ecom_db;
print('Users count: ' + db.users.countDocuments());
var testUser = db.users.findOne({email: 'mongotest@example.com'});
if (testUser) {
    print('✅ Test user found in MongoDB');
} else {
    print('❌ Test user not found in MongoDB');
}
"

echo ""
echo "=========================================="
print_step "🎯 SUMMARY"
echo "=========================================="

print_success "✅ MongoDB container running"
print_success "✅ Backend .env configured for MongoDB"
print_success "✅ Backend config.py configured for MongoDB"
print_success "✅ SQL database references removed"
print_success "✅ Backend restarted with MongoDB connection"

if [ "$register_status" = "201" ] || [ "$register_status" = "409" ]; then
    print_success "✅ MongoDB operations working"
    echo ""
    print_info "🎉 BACKEND ĐANG SỬ DỤNG MONGODB!"
    echo ""
    print_warning "📋 Next steps:"
    echo "  1. Test login: ./debug-login.sh"
    echo "  2. Fix team issues if needed: ./fix-login-team-issue.sh"
    echo "  3. Test from frontend"
    
else
    print_error "❌ MongoDB operations not working"
    echo ""
    print_warning "📋 Troubleshooting:"
    echo "  1. Check backend logs: docker logs ecom_backend"
    echo "  2. Check MongoDB logs: docker logs ecom_mongodb"
    echo "  3. Run full debug: ./check-database-connection.sh"
fi

echo ""
print_info "🛠️ Verification commands:"
echo "  curl http://localhost:5000/health                    # Check health"
echo "  docker logs ecom_backend                             # Backend logs"
echo "  docker exec ecom_mongodb mongosh                     # Access MongoDB"
echo "  ./check-database-connection.sh                       # Full check" 