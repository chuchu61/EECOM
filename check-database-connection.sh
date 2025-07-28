#!/bin/bash

# Script kiểm tra database connection và dữ liệu user
echo "🔍 CHECKING DATABASE CONNECTION & USER DATA"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKEND_URL="http://localhost:5000"

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

# 1. Kiểm tra backend health để xem database gì
print_step "1. Kiểm tra backend health - database type..."
health_response=$(curl -s "$BACKEND_URL/health" 2>/dev/null)

if [ $? -eq 0 ]; then
    print_success "Backend đang chạy"
    echo ""
    echo "Health response:"
    echo "$health_response" | python3 -m json.tool 2>/dev/null || echo "$health_response"
    
    # Kiểm tra xem có mention database gì không
    if echo "$health_response" | grep -qi "mongodb"; then
        print_info "Backend đang sử dụng MongoDB"
        DB_TYPE="mongodb"
    elif echo "$health_response" | grep -qi "mysql\|postgres\|sql"; then
        print_warning "Backend có thể đang sử dụng SQL database"
        DB_TYPE="sql"
    elif echo "$health_response" | grep -qi "emergency\|in-memory"; then
        print_warning "Backend đang chạy emergency mode - không có database"
        DB_TYPE="emergency"
    else
        print_warning "Không thể xác định database type từ health check"
        DB_TYPE="unknown"
    fi
else
    print_error "Backend không response"
    exit 1
fi

# 2. Kiểm tra MongoDB container và dữ liệu
print_step "2. Kiểm tra MongoDB container và dữ liệu..."

if docker ps | grep -q ecom_mongodb; then
    print_success "MongoDB container đang chạy"
    
    # Kiểm tra connection
    if docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        print_success "MongoDB connection OK"
        MONGO_CLIENT="mongosh"
    elif docker exec ecom_mongodb mongo --eval "db.adminCommand('ping')" &>/dev/null; then
        print_success "MongoDB connection OK (legacy client)"
        MONGO_CLIENT="mongo"
    else
        print_error "MongoDB connection failed"
        MONGO_CLIENT=""
    fi
    
    if [ -n "$MONGO_CLIENT" ]; then
        # Kiểm tra databases
        print_info "Checking MongoDB databases..."
        docker exec ecom_mongodb $MONGO_CLIENT --quiet --eval "
            print('=== DATABASES ===');
            show dbs;
        "
        
        # Kiểm tra users collection
        print_info "Checking users in exp_ecom_db..."
        docker exec ecom_mongodb $MONGO_CLIENT --quiet --eval "
            use exp_ecom_db;
            print('=== USERS COLLECTION ===');
            print('Total users: ' + db.users.countDocuments());
            
            var users = db.users.find().toArray();
            if (users.length > 0) {
                print('\\nUsers found:');
                for (var i = 0; i < users.length; i++) {
                    print('- Email: ' + users[i].email + ' | Username: ' + users[i].username + ' | Team ID: ' + users[i].team_id);
                }
            } else {
                print('No users found in collection');
            }
        "
        
        # Kiểm tra teams collection
        print_info "Checking teams in exp_ecom_db..."
        docker exec ecom_mongodb $MONGO_CLIENT --quiet --eval "
            use exp_ecom_db;
            print('=== TEAMS COLLECTION ===');
            print('Total teams: ' + db.teams.countDocuments());
            
            var teams = db.teams.find().toArray();
            if (teams.length > 0) {
                print('\\nTeams found:');
                for (var i = 0; i < teams.length; i++) {
                    print('- Name: ' + teams[i].name + ' | ID: ' + teams[i]._id);
                }
            } else {
                print('No teams found in collection');
            }
        "
    fi
    
else
    print_error "MongoDB container không chạy"
    print_info "MongoDB container cần thiết cho login"
fi

# 3. Kiểm tra backend configuration
print_step "3. Kiểm tra backend configuration..."

if docker ps | grep -q ecom_backend; then
    print_info "Checking backend environment variables..."
    docker exec ecom_backend env | grep -E "(MONGO|DB|DATABASE)" || echo "No database environment variables found"
    
    print_info "Checking backend logs for database connection..."
    echo "Recent backend logs:"
    docker logs ecom_backend --tail=20 | grep -i -E "(mongo|database|connection|error)" || echo "No database-related logs found"
    
else
    print_warning "Backend container không chạy"
fi

# 4. Kiểm tra backend config files
print_step "4. Kiểm tra backend config files..."

if [ -f "backend/.env" ]; then
    print_info "Backend .env file:"
    cat backend/.env | grep -v -E "(SECRET|PASSWORD)" # Hide sensitive info
else
    print_warning "Backend .env file không tồn tại"
fi

print_info "Backend config.py:"
head -20 backend/config.py

# 5. Test actual login API call
print_step "5. Test login API với dữ liệu MongoDB..."

# Lấy một user từ MongoDB để test
if [ -n "$MONGO_CLIENT" ] && docker ps | grep -q ecom_mongodb; then
    print_info "Lấy user đầu tiên từ MongoDB để test..."
    
    USER_DATA=$(docker exec ecom_mongodb $MONGO_CLIENT --quiet --eval "
        use exp_ecom_db;
        var user = db.users.findOne();
        if (user) {
            print(JSON.stringify({
                email: user.email,
                username: user.username,
                hasPassword: user.password ? true : false,
                hasTeamId: user.team_id ? true : false
            }));
        } else {
            print('NO_USER_FOUND');
        }
    ")
    
    if [ "$USER_DATA" != "NO_USER_FOUND" ]; then
        echo "User data từ MongoDB:"
        echo "$USER_DATA" | python3 -m json.tool 2>/dev/null || echo "$USER_DATA"
        
        # Extract email
        USER_EMAIL=$(echo "$USER_DATA" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('email', ''))
except:
    print('')
")
        
        if [ -n "$USER_EMAIL" ]; then
            print_info "Testing login với user: $USER_EMAIL"
            
            # Test với password mặc định hoặc yêu cầu user nhập
            echo ""
            print_warning "Để test login, bạn cần nhập password cho user: $USER_EMAIL"
            echo "Hoặc sử dụng password test nếu bạn tạo user test:"
            echo ""
            
            # Test với test password
            test_login_data="{\"email\":\"$USER_EMAIL\",\"password\":\"testpassword123\"}"
            
            print_info "Testing login..."
            login_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/login" \
                -H "Content-Type: application/json" \
                -d "$test_login_data")
            
            login_status=$(echo "$login_response" | tail -1)
            login_body=$(echo "$login_response" | head -1)
            
            echo "Login response:"
            echo "$login_body" | python3 -m json.tool 2>/dev/null || echo "$login_body"
            echo "Status: $login_status"
            
            # Phân tích lỗi
            case $login_status in
                200)
                    print_success "Login thành công!"
                    ;;
                401)
                    print_error "Login failed: Invalid credentials"
                    print_info "Password có thể không đúng hoặc user không tồn tại"
                    ;;
                402)
                    print_error "Login failed: User not active / team issues"
                    print_info "User cần có team_id và team phải tồn tại"
                    ;;
                500)
                    print_error "Login failed: Server error"
                    print_info "Có thể backend không kết nối được MongoDB"
                    ;;
                *)
                    print_error "Login failed: Status $login_status"
                    ;;
            esac
        fi
    else
        print_warning "Không tìm thấy user trong MongoDB"
    fi
else
    print_warning "Không thể test login - MongoDB không available"
fi

# 6. Kết luận và đề xuất
echo ""
echo "=========================================="
print_step "🎯 DIAGNOSIS & RECOMMENDATIONS"
echo "=========================================="

echo ""
print_info "🔍 FINDINGS:"

if [ "$DB_TYPE" = "emergency" ]; then
    print_error "VẤN ĐỀ: Backend đang chạy EMERGENCY MODE"
    echo "  • Không có database connection"
    echo "  • Login sẽ không hoạt động"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Fix MongoDB: ./fix-mongodb.sh"
    echo "  2️⃣ Restart backend normal: ./start-backend-simple.sh"
    
elif [ "$DB_TYPE" = "sql" ]; then
    print_error "VẤN ĐỀ: Backend đang cố kết nối SQL database"
    echo "  • Cấu hình sai database type"
    echo "  • Cần đổi về MongoDB"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Check backend config.py và .env"
    echo "  2️⃣ Đảm bảo MONGO_URI đúng"
    echo "  3️⃣ Restart backend"
    
elif ! docker ps | grep -q ecom_mongodb; then
    print_error "VẤN ĐỀ: MongoDB container không chạy"
    echo "  • Backend cần MongoDB để authentication"
    echo "  • User data trong MongoDB không accessible"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Khởi động MongoDB: ./fix-mongodb.sh"
    echo "  2️⃣ Restart backend: docker restart ecom_backend"
    
elif [ "$login_status" = "402" ]; then
    print_error "VẤN ĐỀ: User có trong MongoDB nhưng thiếu team"
    echo "  • User cần có team_id"
    echo "  • Team phải tồn tại trong database"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Fix team issue: ./fix-login-team-issue.sh"
    echo "  2️⃣ Hoặc disable team check: ./disable-team-check.sh"
    
elif [ "$login_status" = "500" ]; then
    print_error "VẤN ĐỀ: Backend không kết nối được MongoDB"
    echo "  • Connection string có thể sai"
    echo "  • MongoDB network issues"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Check connection: docker logs ecom_backend"
    echo "  2️⃣ Restart containers: docker restart ecom_mongodb ecom_backend"
    
else
    print_success "Setup có vẻ OK, cần debug thêm"
    echo ""
    print_info "NEXT STEPS:"
    echo "  1️⃣ Debug login chi tiết: ./debug-login.sh"
    echo "  2️⃣ Check frontend console errors"
    echo "  3️⃣ Check network requests"
fi

echo ""
print_info "🛠️ USEFUL COMMANDS:"
echo "  docker logs ecom_backend              # Backend logs"
echo "  docker logs ecom_mongodb              # MongoDB logs"
echo "  docker exec ecom_mongodb mongosh      # Access MongoDB"
echo "  ./debug-login.sh                      # Full login debug"
echo "  ./fix-login-team-issue.sh             # Fix team issues" 