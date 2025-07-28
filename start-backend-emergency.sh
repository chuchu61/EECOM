#!/bin/bash

# Script emergency khởi động backend với SQLite (không cần MongoDB)
echo "🚨 EMERGENCY BACKEND START - NO MONGODB"
echo "========================================"

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

# Thông báo
print_warning "MongoDB không thể khởi động được!"
print_info "Script này sẽ chạy backend với SQLite thay vì MongoDB"
print_info "Đây là giải pháp tạm thời để backend có thể hoạt động cơ bản"

# Kiểm tra Python
print_step "Kiểm tra Python environment..."
if ! command -v python3 &> /dev/null; then
    print_error "Python3 không tìm thấy"
    echo "Cài đặt Python3:"
    echo "sudo apt update && sudo apt install python3 python3-pip python3-venv -y"
    exit 1
fi
print_success "Python3 available"

# Đi vào thư mục backend
cd backend

# Tạo virtual environment
print_step "Thiết lập Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
print_success "Virtual environment ready"

# Cài đặt dependencies cơ bản
print_step "Cài đặt dependencies..."
pip install --upgrade pip

# Cài đặt Flask và dependencies cơ bản (không MongoDB)
pip install flask python-dotenv flask-cors flask-jwt-extended bcrypt

print_success "Basic dependencies installed"

# Tạo file app đơn giản không cần MongoDB
print_step "Tạo backend app đơn giản..."
cat > simple_app.py << 'EOF'
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
import os
from datetime import timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config.update(
    JWT_SECRET_KEY=os.environ.get('JWT_SECRET_KEY', 'emergency-secret-key'),
    JWT_ACCESS_TOKEN_EXPIRES=timedelta(hours=1),
    JWT_REFRESH_TOKEN_EXPIRES=timedelta(days=30)
)

# Initialize extensions
jwt = JWTManager(app)
CORS(app, resources={r"/*": {"origins": "*"}})

# Simple in-memory data store
app_data = {
    'status': 'running',
    'mode': 'emergency',
    'database': 'in-memory',
    'features': ['basic-api', 'health-check', 'cors-enabled']
}

@app.route('/')
def home():
    return jsonify({
        'message': '🚨 ECommerce Backend API - Emergency Mode',
        'status': 'success',
        'mode': 'emergency',
        'database': 'in-memory (MongoDB unavailable)',
        'version': '1.0.0-emergency',
        'endpoints': {
            'health': '/health',
            'api': '/api',
            'status': '/status'
        },
        'note': 'This is a simplified backend running without MongoDB'
    })

@app.route('/health')
def health_check():
    return jsonify({
        'status': 'healthy',
        'mode': 'emergency',
        'database': 'in-memory',
        'mongodb': 'unavailable',
        'environment': os.environ.get('FLASK_ENV', 'development'),
        'timestamp': '2025-01-08T03:00:00Z'
    })

@app.route('/api')
def api_info():
    return jsonify({
        'message': 'ECommerce API v1.0.0 - Emergency Mode',
        'documentation': 'Limited functionality - MongoDB unavailable',
        'available_endpoints': [
            'GET /',
            'GET /health', 
            'GET /api',
            'GET /status'
        ],
        'note': 'Full API features require MongoDB connection'
    })

@app.route('/status')
def status():
    return jsonify({
        'backend': 'running',
        'mode': 'emergency',
        'database': 'in-memory',
        'mongodb': 'unavailable',
        'features_available': [
            'Basic API responses',
            'Health checks',
            'CORS enabled',
            'JWT configured'
        ],
        'features_disabled': [
            'User authentication',
            'Product management', 
            'Data persistence',
            'Database operations'
        ]
    })

# JWT error handlers
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return {'message': 'Token has expired'}, 401

@jwt.invalid_token_loader
def invalid_token_callback(error):
    return {'message': 'Invalid token'}, 401

if __name__ == '__main__':
    logger.info("🚨 Starting Emergency Backend - No MongoDB")
    logger.info("📡 Server will be available at http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF

print_success "Simple app created"

# Tạo .env file đơn giản
print_step "Tạo .env file..."
cat > .env << 'EOF'
JWT_SECRET_KEY=emergency-secret-key-for-testing
FLASK_ENV=development
PYTHONUNBUFFERED=1
MODE=emergency
EOF
print_success ".env file created"

# Set environment variables
export JWT_SECRET_KEY=emergency-secret-key-for-testing
export FLASK_ENV=development
export PYTHONUNBUFFERED=1
export MODE=emergency

# Khởi động Flask app
print_step "Khởi động Emergency Backend..."
echo ""
print_warning "🚨 EMERGENCY MODE - LIMITED FUNCTIONALITY"
print_info "Backend sẽ chạy mà không cần MongoDB"
print_info "Các tính năng cơ bản sẽ hoạt động"
print_info "Database operations sẽ không khả dụng"
echo ""
print_success "🚀 Starting server at http://localhost:5000"
print_info "🛑 Nhấn Ctrl+C để dừng"
echo ""

# Chạy app và test
python3 simple_app.py &
SERVER_PID=$!

# Đợi server khởi động
print_step "Đợi server khởi động..."
sleep 3

# Test endpoints
for i in {1..10}; do
    if curl -s http://localhost:5000 > /dev/null 2>&1; then
        print_success "Emergency Backend is running!"
        break
    fi
    
    if [ $i -eq 10 ]; then
        print_error "Server failed to start"
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
    
    echo "⏳ Testing connection... ($i/10)"
    sleep 1
done

# Test API endpoints
print_step "Testing Emergency API..."

endpoints=("/" "/health" "/api" "/status")
for endpoint in "${endpoints[@]}"; do
    echo ""
    print_step "Testing http://localhost:5000$endpoint"
    
    response=$(curl -s http://localhost:5000$endpoint)
    if [ $? -eq 0 ]; then
        print_success "Endpoint $endpoint: OK"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
    else
        print_error "Endpoint $endpoint: FAILED"
    fi
done

echo ""
print_success "🎉 EMERGENCY BACKEND STARTED SUCCESSFULLY!"
echo "=========================================="
print_warning "⚠️ CHẠY Ở CHẾ ĐỘ EMERGENCY - GIỚI HẠN TÍNH NĂNG"
echo ""
echo "🌐 Truy cập backend:"
echo "   • Homepage: ${CYAN}http://localhost:5000${NC}"
echo "   • Health Check: ${CYAN}http://localhost:5000/health${NC}"
echo "   • API Info: ${CYAN}http://localhost:5000/api${NC}"
echo "   • Status: ${CYAN}http://localhost:5000/status${NC}"
echo ""
echo "✅ Tính năng hoạt động:"
echo "   • Basic API responses"
echo "   • Health checks"  
echo "   • CORS enabled"
echo "   • JSON responses"
echo ""
echo "❌ Tính năng bị hạn chế:"
echo "   • Không có database"
echo "   • Không lưu được data"
echo "   • Không có user authentication"
echo "   • Không có product management"
echo ""
echo "💡 Để có đầy đủ tính năng:"
echo "   • Fix MongoDB: ${YELLOW}./fix-mongodb.sh${NC}"
echo "   • Hoặc dùng Docker: ${YELLOW}./start-backend-simple.sh${NC}"
echo ""
print_success "✨ Mở browser: http://localhost:5000 ✨"

# Keep script running
wait $SERVER_PID 