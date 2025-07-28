# 🚀 Khởi động Backend - Hướng dẫn đầy đủ

## 🔥 QUICK START (Nếu backend không chạy)

### 🔍 Bước 1: Debug vấn đề
```bash
chmod +x debug-backend.sh
./debug-backend.sh
```

### 🚀 Bước 2: Thử các phương pháp khởi động

#### Option A: Docker Compose (Khuyến nghị)
```bash
chmod +x start-backend.sh
./start-backend.sh
```

#### Option B: Docker đơn giản (Nếu Compose lỗi)
```bash
chmod +x start-backend-simple.sh
./start-backend-simple.sh
```

#### Option C: Native Python (Nếu Docker lỗi)
```bash
chmod +x start-backend-native.sh
./start-backend-native.sh
```

---

## ✅ Chi tiết các phương pháp

### 🐳 1. Docker Compose Method

**Script:** `start-backend.sh`
**Ưu điểm:** Đầy đủ tính năng, auto-scaling, health checks
**Nhược điểm:** Phức tạp, có thể gặp lỗi config

```bash
# Chạy tự động
./start-backend.sh

# Hoặc thủ công
docker-compose up -d --build backend mongodb
```

### 🔧 2. Docker Simple Method

**Script:** `start-backend-simple.sh`
**Ưu điểm:** Đơn giản, dễ debug, ít lỗi
**Nhược điểm:** Không có auto-scaling

```bash
# Chạy script
./start-backend-simple.sh

# Logs nếu cần
docker logs ecom_backend
docker logs ecom_mongodb
```

### 🖥️ 3. Native Python Method

**Script:** `start-backend-native.sh`
**Ưu điểm:** Không phụ thuộc Docker, debug dễ
**Nhược điểm:** Cần cài Python dependencies

```bash
# Chạy script
./start-backend-native.sh

# Hoặc manual
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 wsgi.py
```

---

## 🌐 Test Backend trong Browser

Sau khi khởi động thành công:
- **Root API**: http://localhost:5000
- **Health Check**: http://localhost:5000/health  
- **API Info**: http://localhost:5000/api

---

## 🔍 Debugging Tools

### Script debug tự động:
```bash
./debug-backend.sh
```

### Manual debugging:
```bash
# Kiểm tra containers
docker ps | grep ecom

# Xem logs
docker logs ecom_backend
docker logs ecom_mongodb

# Test port
curl http://localhost:5000
netstat -tulpn | grep :5000

# Test health
curl http://localhost:5000/health | python3 -m json.tool
```

---

## 🎯 Troubleshooting

### ❌ Backend không response trong browser:

**1. Kiểm tra container đang chạy:**
```bash
docker ps | grep ecom_backend
```

**2. Kiểm tra logs:**
```bash
docker logs ecom_backend
```

**3. Test từ terminal:**
```bash
curl http://localhost:5000
curl http://127.0.0.1:5000
```

**4. Kiểm tra port binding:**
```bash
netstat -tulpn | grep :5000
```

### ❌ Port 5000 bị chiếm:
```bash
# Tìm process
lsof -i :5000

# Kill process
kill -9 <PID>

# Hoặc dùng port khác
docker run -p 5001:5000 ...
```

### ❌ MongoDB connection failed:
```bash
# Restart MongoDB
docker restart ecom_mongodb

# Test connection
docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')"
```

### ❌ WSL port forwarding issue:
```bash
# Trong PowerShell (Run as Administrator)
netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectport=5000 connectaddress=<WSL_IP>

# Tìm WSL IP
wsl hostname -I
```

### ❌ Docker Compose lỗi:
```bash
# Dọn dẹp hoàn toàn
docker-compose down -v --remove-orphans
docker system prune -f

# Thử simple method
./start-backend-simple.sh
```

---

## 📊 Monitoring & Logs

### Real-time monitoring:
```bash
# Logs theo thời gian thực
docker-compose logs -f backend

# Stats containers
docker stats ecom_backend ecom_mongodb

# Health status
docker-compose ps
```

### Log analysis:
```bash
# Backend logs chi tiết
docker logs ecom_backend --since 5m

# MongoDB logs
docker logs ecom_mongodb --since 5m

# Lỗi gần đây nhất
docker logs ecom_backend 2>&1 | grep -i error
```

---

## 🛠️ Manual Commands

### Khởi động thủ công:
```bash
# MongoDB
docker run -d --name ecom_mongodb -p 27017:27017 mongo:5.0

# Backend
docker build -t ecom_backend ./backend
docker run -d --name ecom_backend -p 5000:5000 \
  -e MONGO_URI=mongodb://host.docker.internal:27017/exp_ecom_db \
  ecom_backend
```

### Testing manual:
```bash
# Root endpoint
curl http://localhost:5000

# Health với format
curl http://localhost:5000/health | python3 -m json.tool

# API endpoints
curl http://localhost:5000/api | python3 -m json.tool
```

### Stop services:
```bash
# Stop containers
docker stop ecom_backend ecom_mongodb

# Remove containers
docker rm ecom_backend ecom_mongodb

# Clean everything
docker system prune -f
```

---

## 🎯 Final Notes

1. **Nếu vẫn không chạy được:** Hãy chạy `./debug-backend.sh` và gửi output cho developer
2. **Performance issue:** Thử native method với `./start-backend-native.sh`
3. **Network issue:** Kiểm tra firewall và WSL port forwarding
4. **Development:** Dùng native method để hot-reload code
5. **Production:** Dùng Docker Compose method

**Support:** Nếu tất cả methods đều fail, likely là vấn đề với network/firewall/WSL configuration. 