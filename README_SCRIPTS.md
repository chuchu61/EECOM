# 🚀 Ecom Backend + MongoDB Setup Scripts

Bộ script tự động để setup và chạy backend + MongoDB một cách hoàn chỉnh.

## 📋 Danh sách Scripts

### 1. `setup_and_run.sh` - Setup và chạy hoàn chỉnh
```bash
./setup_and_run.sh
```
**Chức năng:**
- ✅ Clean up containers/networks cũ
- ✅ Tạo file .env với cấu hình đúng
- ✅ Setup virtual environment mới
- ✅ Cài đặt tất cả dependencies
- ✅ Fix AWS service để tránh crash
- ✅ Khởi động MongoDB container
- ✅ Khởi động backend server
- ✅ Test kết nối và hiển thị thông tin

### 2. `restart_services.sh` - Khởi động lại nhanh
```bash
./restart_services.sh
```
**Chức năng:**
- 🔄 Khởi động lại MongoDB và backend
- ⚡ Không cần setup lại từ đầu
- 🔍 Kiểm tra cấu hình có sẵn

### 3. `stop_services.sh` - Dừng services
```bash
./stop_services.sh
```
**Chức năng:**
- 🛑 Dừng backend server
- 🛑 Dừng MongoDB container
- 🔌 Giải phóng ports 5000 và 27017

### 4. `cleanup_all.sh` - Xóa hoàn toàn
```bash
./cleanup_all.sh
```
**Chức năng:**
- 🗑️ Xóa tất cả containers
- 💾 Xóa tất cả volumes
- 🐍 Xóa virtual environments
- 📁 Xóa file cấu hình tạm

## 🎯 Cách sử dụng

### Lần đầu setup:
```bash
# Tạo executable permission
chmod +x *.sh

# Setup và chạy
./setup_and_run.sh
```

### Sử dụng hàng ngày:
```bash
# Khởi động
./restart_services.sh

# Dừng
./stop_services.sh
```

### Khi có vấn đề:
```bash
# Reset hoàn toàn và setup lại
./cleanup_all.sh
./setup_and_run.sh
```

## 🌐 Địa chỉ truy cập

Sau khi chạy thành công:
- **Backend API**: http://localhost:5000
- **MongoDB**: localhost:27017
- **Frontend**: http://localhost:3000 (nếu chạy riêng)

## 🔧 Cấu hình

### Environment Variables (tự động tạo):
```
JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
MONGO_URI=mongodb://localhost:27017/exp_ecom_db
TESTING=False
AWS_BUCKET_NAME=ecom.sys
AWS_ACCESS_KEY_ID=fake_access_key_for_local_dev
AWS_SECRET_ACCESS_KEY=fake_secret_key_for_local_dev
AWS_DEFAULT_REGION=us-east-1
```

### Ports sử dụng:
- **5000**: Backend Flask server
- **27017**: MongoDB database
- **3000**: Frontend (nếu chạy riêng)

## 🐛 Troubleshooting

### Lỗi "Port already in use":
```bash
./stop_services.sh
./restart_services.sh
```

### Lỗi "Container name conflict":
```bash
./cleanup_all.sh
./setup_and_run.sh
```

### Lỗi dependencies Python:
```bash
# Vào thư mục backend
cd backend
source venv_production/bin/activate
pip install -r requirements.txt
```

### Lỗi MongoDB connection:
```bash
# Kiểm tra MongoDB
docker logs ecom_mongodb
docker exec ecom_mongodb mongosh --eval "db.runCommand('ping')"
```

## 📝 Logs và Debug

### Xem logs MongoDB:
```bash
docker logs ecom_mongodb
```

### Xem logs backend:
```bash
# Backend logs hiển thị trực tiếp trong terminal
# Hoặc check file logs nếu có
```

### Test API:
```bash
curl http://localhost:5000
```

## 🔄 Workflow khuyến nghị

1. **Lần đầu**: `./setup_and_run.sh`
2. **Hàng ngày**: `./restart_services.sh`
3. **Khi xong việc**: `./stop_services.sh`
4. **Khi có vấn đề**: `./cleanup_all.sh` → `./setup_and_run.sh`

## ⚠️ Lưu ý

- Scripts phải chạy từ thư mục gốc project (có file docker-compose.yml)
- Cần có Docker đã cài đặt và đang chạy
- Cần có Python 3.8+ và pip
- MongoDB data sẽ được lưu trong Docker volume `mongodb_data`
- Virtual environment sẽ được tạo trong `backend/venv_production` 