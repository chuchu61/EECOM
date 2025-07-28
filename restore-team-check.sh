#!/bin/bash

# Script restore team check từ backup
echo "🔄 RESTORING TEAM CHECK FROM BACKUP"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Kiểm tra backup file tồn tại
if [ ! -f "backend/app/routes/auth.py.backup" ]; then
    print_error "Backup file không tồn tại: auth.py.backup"
    print_info "Không thể restore team check"
    exit 1
fi

print_info "Found backup file: auth.py.backup"

# Restore từ backup
cp backend/app/routes/auth.py.backup backend/app/routes/auth.py
print_success "✅ Team check restored từ backup"

# Restart backend
if docker ps | grep -q ecom_backend; then
    print_info "Restarting backend container..."
    docker restart ecom_backend
    sleep 5
    print_success "Backend restarted"
else
    print_warning "Backend container không chạy"
    print_info "Cần khởi động backend sau khi restore"
fi

echo ""
print_warning "⚠️ TEAM CHECK ĐÃ ĐƯỢC RESTORE"
print_info "Users bây giờ cần có team_id để login"
print_info "Nếu cần disable lại: ./disable-team-check.sh"
print_info "Nếu cần tạo team: ./fix-login-team-issue.sh" 