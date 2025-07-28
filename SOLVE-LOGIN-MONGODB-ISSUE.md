# 🔧 GIẢI QUYẾT VẤN ĐỀ LOGIN: MongoDB vs SQL Database

## ❗ VẤN ĐỀ

Bạn đang gặp tình huống:
- **Dữ liệu user đã có trong MongoDB** 
- **Login báo lỗi API**
- **Backend có thể đang cố kết nối SQL database thay vì MongoDB**

## 🔍 CHẨN ĐOÁN

### 1. Kiểm tra Backend đang connect database nào
```bash
./check-database-connection.sh
```

Script này sẽ:
- ✅ Kiểm tra backend health và database type
- ✅ Kiểm tra MongoDB container và dữ liệu
- ✅ Kiểm tra backend configuration
- ✅ Test actual login API
- ✅ Đưa ra diagnosis và recommendations

### 2. Đảm bảo Backend kết nối đúng MongoDB
```bash
./ensure-mongodb-connection.sh
```

Script này sẽ:
- ✅ Khởi động MongoDB nếu chưa chạy
- ✅ Update backend `.env` để force MongoDB
- ✅ Update backend `config.py` để disable SQL
- ✅ Remove SQL imports từ code
- ✅ Restart backend với MongoDB configuration
- ✅ Test MongoDB operations

## 🎯 CÁC TÌNH HUỐNG THƯỜNG GẶP

### Tình huống 1: Backend đang chạy Emergency Mode
**Triệu chứng:** Health check shows "emergency" or "in-memory"
**Nguyên nhân:** Backend không kết nối được database
**Giải pháp:**
```bash
./fix-mongodb.sh
./start-backend-simple.sh
```

### Tình huống 2: Backend cố kết nối SQL Database
**Triệu chứng:** Health check mentions SQL/MySQL/PostgreSQL
**Nguyên nhân:** Config sai, có SQL imports trong code
**Giải pháp:**
```bash
./ensure-mongodb-connection.sh
```

### Tình huống 3: MongoDB container không chạy
**Triệu chứng:** Cannot connect to MongoDB
**Nguyên nhân:** MongoDB service down
**Giải pháp:**
```bash
./fix-mongodb.sh
docker restart ecom_backend
```

### Tình huống 4: User có trong MongoDB nhưng thiếu team
**Triệu chứng:** Login returns 402 "User not active"
**Nguyên nhân:** Backend yêu cầu user phải có team_id
**Giải pháp:**
```bash
./fix-login-team-issue.sh
# hoặc
./disable-team-check.sh
```

### Tình huống 5: Backend không connect được MongoDB
**Triệu chứng:** Login returns 500 server error
**Nguyên nhân:** Connection string sai, network issues
**Giải pháp:**
```bash
docker logs ecom_backend
./ensure-mongodb-connection.sh
```

## 📋 QUY TRÌNH GIẢI QUYẾT TOÀN BỘ

### Bước 1: Chẩn đoán
```bash
./check-database-connection.sh
```

### Bước 2: Fix Database Connection
```bash
./ensure-mongodb-connection.sh
```

### Bước 3: Fix Team Issues (nếu cần)
```bash
./fix-login-team-issue.sh
```

### Bước 4: Test Login
```bash
./debug-login.sh
```

## 🔧 CÁC COMMANDS HỮU ÍCH

### Kiểm tra trạng thái containers
```bash
docker ps                                  # Xem containers đang chạy
docker logs ecom_backend                   # Backend logs
docker logs ecom_mongodb                   # MongoDB logs
```

### Test MongoDB trực tiếp
```bash
docker exec ecom_mongodb mongosh           # Access MongoDB shell
# Trong mongosh:
use exp_ecom_db
db.users.find()                           # Xem users
db.teams.find()                           # Xem teams
```

### Test Backend API
```bash
curl http://localhost:5000/health          # Health check
curl http://localhost:5000/                # Root endpoint
curl http://localhost:5000/api             # API root
```

### Reset và khởi động lại clean
```bash
docker stop ecom_backend ecom_mongodb
docker rm ecom_backend ecom_mongodb
./ensure-mongodb-connection.sh
```

## 📁 CÁC FILE QUAN TRỌNG

### Backend Configuration
- `backend/.env` - Environment variables
- `backend/config.py` - Database configuration  
- `backend/app/__init__.py` - App initialization

### Login Logic
- `backend/app/routes/auth.py` - Authentication routes
- Lines 88-96: Team validation logic

### Scripts
- `check-database-connection.sh` - Diagnosis script
- `ensure-mongodb-connection.sh` - Fix MongoDB connection
- `fix-login-team-issue.sh` - Fix team requirements
- `disable-team-check.sh` - Bypass team check
- `debug-login.sh` - Debug login process

## 🚨 TROUBLESHOOTING TIPS

### Nếu scripts không chạy được
```bash
# Windows PowerShell:
bash ./check-database-connection.sh
bash ./ensure-mongodb-connection.sh

# WSL/Linux:
./check-database-connection.sh
./ensure-mongodb-connection.sh
```

### Nếu MongoDB start failed
```bash
docker system prune -f                    # Clean up Docker
docker volume rm ecom_mongo_data          # Remove old volume
./fix-mongodb.sh                          # Recreate MongoDB
```

### Nếu backend build failed  
```bash
cd backend
docker build -t ecom_backend_img .        # Rebuild image
cd ..
./ensure-mongodb-connection.sh            # Restart
```

### Nếu vẫn không login được
1. Check frontend console errors
2. Check network requests in browser devtools
3. Verify user credentials in MongoDB
4. Test with different browsers
5. Check CORS settings

## ✅ KIỂM TRA THÀNH CÔNG

Khi mọi thứ hoạt động đúng:
- ✅ `curl http://localhost:5000/health` returns MongoDB connection
- ✅ MongoDB container running: `docker ps | grep ecom_mongodb`
- ✅ Backend container running: `docker ps | grep ecom_backend`
- ✅ Users exist in MongoDB: Check via mongosh
- ✅ Teams exist or team check disabled
- ✅ Login API returns 200 với valid credentials

## 📞 HỖ TRỢ

Nếu vẫn gặp vấn đề, chạy:
```bash
./check-database-connection.sh > diagnosis.log 2>&1
```

Và chia sẻ file `diagnosis.log` để được hỗ trợ chi tiết. 