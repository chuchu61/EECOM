# ⚡ QUICK START - BACKEND

## 🚨 Backend không chạy được? Chỉ cần 1 lệnh! 

```bash
cd /mnt/c/Users/Mr\ Minh/OneDrive/ドキュメント/GitHub/ecom

chmod +x start-backend-auto-fix.sh
./start-backend-auto-fix.sh
```

---

## 🔐 Backend chạy được nhưng không login được?

### 🔍 Bước 1: Debug login issue
```bash
chmod +x debug-login.sh
./debug-login.sh
```

### 🛠️ Bước 2: Fix login (chọn 1 trong 2)

#### Option A: Tạo team và assign user (Khuyến nghị)
```bash
chmod +x fix-login-team-issue.sh
./fix-login-team-issue.sh
```

#### Option B: Tạm thời disable team check (Development)
```bash
chmod +x disable-team-check.sh
./disable-team-check.sh
```

---

## 🆘 EMERGENCY METHODS (nếu MongoDB hoàn toàn không chạy)

### 🚨 Method Emergency: No MongoDB Required
```bash
chmod +x start-backend-emergency.sh
./start-backend-emergency.sh
```
**Đặc điểm:**
- ✅ Chạy mà không cần MongoDB
- ✅ Backend cơ bản hoạt động  
- ✅ API endpoints basic
- ❌ Không có database persistence
- ❌ Không có user authentication

### 🧪 Method Ultra-Simple: Test Python Flask
```bash
chmod +x test-python-flask.sh
./test-python-flask.sh
```
**Đặc điểm:**
- ✅ Test cơ bản nhất
- ✅ Chỉ cần Python + Flask
- ✅ Không cần Docker, MongoDB
- 🎯 Để test system có thể chạy Flask không

---

## 🔥 BACKUP METHODS (nếu auto-fix không work)

### Method 1: Fix MongoDB riêng
```bash
./fix-mongodb.sh
./start-backend-simple.sh
```

### Method 2: Native Python (không Docker)
```bash
./start-backend-native.sh
```

### Method 3: Debug issue
```bash
./debug-backend.sh
```

---

## 🌐 Kết quả mong đợi

### ✅ Normal Mode (với MongoDB):
```
🎉 Backend khởi động thành công!

🌐 Truy cập backend:
   • Homepage: http://localhost:5000
   • Health Check: http://localhost:5000/health
   • API Docs: http://localhost:5000/api
```

### 🔐 Login Success:
```
🎉 LOGIN FIX THÀNH CÔNG!

Login response includes:
  ✅ Access Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
  ✅ Email: user@example.com
  ✅ Username: username
  ✅ Team Name: Default Team
  ✅ Role: user
```

### 🚨 Emergency Mode (không MongoDB):
```
🎉 EMERGENCY BACKEND STARTED SUCCESSFULLY!
⚠️ CHẠY Ở CHẾ ĐỘ EMERGENCY - GIỚI HẠN TÍNH NĂNG

🌐 Truy cập backend:
   • Homepage: http://localhost:5000
   • Health Check: http://localhost:5000/health
   • API Info: http://localhost:5000/api
   • Status: http://localhost:5000/status
```

**Mở browser và test:** http://localhost:5000

---

## ❌ Troubleshooting Login Issues

### 🔍 Error 402: "User not active" hoặc "team not found"
**Nguyên nhân:** Backend yêu cầu user phải có team_id và team phải tồn tại

**Giải pháp:**
```bash
# Option 1: Tạo team và assign user
./fix-login-team-issue.sh

# Option 2: Disable team check tạm thời
./disable-team-check.sh
```

### 🔍 Error 401: "Invalid credentials"
**Nguyên nhân:** Email/password không đúng

**Giải pháp:**
- Kiểm tra email và password
- Đảm bảo user đã được tạo
- Test với user mới

### 🔍 Error 500: "Server error"
**Nguyên nhân:** MongoDB connection issues

**Giải pháp:**
```bash
# Fix MongoDB
./fix-mongodb.sh

# Hoặc dùng emergency mode
./start-backend-emergency.sh
```

### 🔍 Backend chạy emergency mode
**Nguyên nhân:** MongoDB không khởi động được

**Giải pháp:**
```bash
# Fix MongoDB trước
./fix-mongodb.sh

# Restart backend normal mode
./start-backend-simple.sh
```

---

## ❌ Nếu vẫn không chạy được

### 1. **Kiểm tra cơ bản:**
```bash
# Test siêu đơn giản
./test-python-flask.sh

# Nếu Flask basic cũng không chạy:
sudo apt update
sudo apt install python3 python3-pip -y
```

### 2. **Debug toàn diện:**
```bash
# Debug backend
./debug-backend.sh

# Debug login
./debug-login.sh
```

### 3. **Kiểm tra Docker:**
```bash
sudo systemctl status docker
sudo systemctl start docker
```

### 4. **Thử Emergency Mode:**
```bash
./start-backend-emergency.sh
```

### 5. **Check Windows Firewall:**
- WSL có thể bị block bởi Windows Firewall
- Thử tắt firewall tạm thời để test

### 6. **Contact support:**
- Copy output của `debug-backend.sh` và `debug-login.sh`
- Gửi cho developer để support

---

## 📋 Useful Commands

```bash
# Backend management
docker restart ecom_backend
docker logs ecom_backend
docker logs ecom_mongodb
docker stop ecom_backend ecom_mongodb
docker system prune -f

# Login debugging
./debug-login.sh
./fix-login-team-issue.sh
./disable-team-check.sh
./restore-team-check.sh

# Emergency modes
./start-backend-emergency.sh
./test-python-flask.sh

# Test login manually
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'
```

---

## 🎯 Methods Priority Order

### 🥇 First Try: Auto-fix
```bash
./start-backend-auto-fix.sh
```

### 🔐 If Login fails: Debug & Fix
```bash
./debug-login.sh
./fix-login-team-issue.sh
```

### 🥈 If MongoDB fails: Emergency
```bash
./start-backend-emergency.sh
```

### 🥉 If Python fails: Ultra-simple
```bash
./test-python-flask.sh
```

### 🔧 If all fails: Debug
```bash
./debug-backend.sh
```

---

## 🎯 TL;DR

### Backend không chạy:
```bash
./start-backend-auto-fix.sh
```

### Backend chạy nhưng login không được:
```bash
./debug-login.sh
./fix-login-team-issue.sh
```

### MongoDB Problems:
```bash
./start-backend-emergency.sh
```

### System Problems:
```bash
./test-python-flask.sh
```

**Và mở:** http://localhost:5000

🎉 **Done!** 