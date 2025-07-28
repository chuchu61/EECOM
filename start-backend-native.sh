#!/bin/bash

# Script chạy backend trực tiếp trên WSL (không Docker)
echo "🖥️ KHỞI ĐỘNG BACKEND - NATIVE MODE"
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

# Kiểm tra Python
print_step "Kiểm tra Python environment..."
python3 --version
if [ $? -eq 0 ]; then
    print_success "Python3 available"
else
    print_error "Python3 not found. Please install: sudo apt install python3 python3-pip"
    exit 1
fi

# Kiểm tra MongoDB (Docker)
print_step "Khởi động MongoDB (Docker)..."
docker stop ecom_mongodb 2>/dev/null || true
docker run -d --name ecom_mongodb -p 27017:27017 -e MONGO_INITDB_DATABASE=exp_ecom_db mongo:5.0

# Đợi MongoDB
print_step "Đợi MongoDB sẵn sàng..."
for i in {1..20}; do
    if docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        print_success "MongoDB ready!"
        break
    fi
    echo "⏳ Waiting for MongoDB... ($i/20)"
    sleep 2
done

# Đi vào thư mục backend
cd backend

# Tạo virtual environment
print_step "Thiết lập Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
fi

# Kích hoạt venv
source venv/bin/activate
print_success "Virtual environment activated"

# Cài đặt dependencies
print_step "Cài đặt Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    print_success "Dependencies installed"
else
    print_error "Failed to install dependencies"
    exit 1
fi

# Tạo .env file
print_step "Tạo .env file..."
cat > .env << 'EOF'
JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
MONGO_URI=mongodb://localhost:27017/exp_ecom_db
TESTING=False

AWS_BUCKET_NAME=ecom.sys
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=
EOF
print_success ".env file created"

# Export environment variables
export MONGO_URI=mongodb://localhost:27017/exp_ecom_db
export JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
export FLASK_ENV=development
export PYTHONUNBUFFERED=1

# Khởi động Flask app
print_step "Khởi động Flask application..."
echo "🚀 Starting Flask server..."
echo "📡 Backend sẽ chạy tại: http://localhost:5000"
echo "🛑 Nhấn Ctrl+C để dừng"
echo ""

# Chạy app
python3 wsgi.py &
FLASK_PID=$!

# Đợi server khởi động
print_step "Đợi server khởi động..."
sleep 5

# Test API
for i in {1..10}; do
    if curl -s http://localhost:5000 &>/dev/null; then
        print_success "Backend is running!"
        break
    fi
    echo "⏳ Waiting for backend... ($i/10)"
    sleep 2
done

# Test endpoints
print_step "Testing API..."
echo "📡 Root endpoint:"
curl -s http://localhost:5000 | python3 -m json.tool 2>/dev/null

echo -e "\n📊 Health check:"
curl -s http://localhost:5000/health | python3 -m json.tool 2>/dev/null

echo -e "\n🎉 BACKEND CHẠY THÀNH CÔNG!"
echo "=================================="
echo "🌐 Backend URL: http://localhost:5000"
echo "🗄️ MongoDB: localhost:27017 (Docker)"
echo "🐍 Python: Native (venv)"
echo ""
echo "🌐 Mở trình duyệt: http://localhost:5000"
echo ""
echo "🛑 Để dừng backend: kill $FLASK_PID"
echo "🛑 Hoặc nhấn Ctrl+C trong terminal này"

# Giữ script chạy
wait $FLASK_PID 