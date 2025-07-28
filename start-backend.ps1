# Script khởi động backend bằng Docker Compose cho Windows
Write-Host "🚀 Khởi động Backend với Docker Compose..." -ForegroundColor Green

# Kiểm tra Docker có chạy không
try {
    docker info | Out-Null
    Write-Host "✅ Docker đang chạy" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker không chạy. Vui lòng khởi động Docker Desktop trước." -ForegroundColor Red
    exit 1
}

# Dọn dẹp containers cũ
Write-Host "🧹 Dọn dẹp containers cũ..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null

# Xóa volumes cũ
Write-Host "🗑️ Xóa volumes cũ..." -ForegroundColor Yellow
docker volume prune -f

# Build và khởi động
Write-Host "🔨 Build và khởi động services..." -ForegroundColor Cyan
docker-compose up --build backend mongodb

Write-Host "✅ Backend đã được khởi động!" -ForegroundColor Green
Write-Host "📡 Backend API: http://localhost:5000" -ForegroundColor Blue
Write-Host "🗄️ MongoDB: localhost:27017" -ForegroundColor Blue
Write-Host ""
Write-Host "📋 Để xem logs: docker-compose logs -f backend" -ForegroundColor Gray
Write-Host "🛑 Để dừng: docker-compose down" -ForegroundColor Gray 