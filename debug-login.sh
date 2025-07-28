#!/bin/bash

# Script debug login process
echo "🔍 DEBUGGING LOGIN PROCESS"
echo "=========================="

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

# 1. Kiểm tra backend đang chạy
print_step "1. Kiểm tra backend status..."
if curl -s "$BACKEND_URL" > /dev/null 2>&1; then
    print_success "Backend đang chạy"
    
    # Kiểm tra mode
    response=$(curl -s "$BACKEND_URL")
    if echo "$response" | grep -q "emergency"; then
        print_warning "Backend chạy ở EMERGENCY MODE"
        print_info "Emergency mode không hỗ trợ authentication"
        echo ""
        echo "Emergency mode chỉ có basic endpoints:"
        echo "  • / - Homepage"
        echo "  • /health - Health check"
        echo "  • /api - API info"
        echo "  • /status - Status"
        echo ""
        print_warning "Để có login, cần chạy backend với MongoDB"
        exit 1
    else
        print_success "Backend chạy ở NORMAL MODE"
    fi
else
    print_error "Backend không chạy"
    echo "Khởi động backend: ./start-backend-auto-fix.sh"
    exit 1
fi

# 2. Kiểm tra auth endpoints
print_step "2. Kiểm tra auth endpoints..."

endpoints=("/api/auth/register" "/api/auth/login")
for endpoint in "${endpoints[@]}"; do
    echo ""
    print_info "Testing $endpoint"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BACKEND_URL$endpoint" \
        -H "Content-Type: application/json" \
        -d '{}')
    
    if [ "$response" == "400" ]; then
        print_success "Endpoint $endpoint: AVAILABLE (400 = missing data)"
    elif [ "$response" == "500" ]; then
        print_error "Endpoint $endpoint: SERVER ERROR (MongoDB issue?)"
    else
        print_warning "Endpoint $endpoint: Status $response"
    fi
done

# 3. Test MongoDB connection qua health endpoint
print_step "3. Kiểm tra MongoDB connection..."
health_response=$(curl -s "$BACKEND_URL/health")
echo "$health_response" | python3 -m json.tool 2>/dev/null || echo "$health_response"

if echo "$health_response" | grep -q "connected"; then
    print_success "MongoDB connected"
elif echo "$health_response" | grep -q "error"; then
    print_error "MongoDB connection failed"
    print_warning "Login sẽ không hoạt động without MongoDB"
else
    print_warning "MongoDB status unclear"
fi

# 4. Test register user
print_step "4. Test tạo user mới..."

test_user_data='{
    "email": "testuser@example.com",
    "password": "testpassword123",
    "username": "testuser"
}'

echo "Testing register với data:"
echo "$test_user_data" | python3 -m json.tool

register_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "$test_user_data")

status_code=$(echo "$register_response" | tail -1)
response_body=$(echo "$register_response" | head -1)

echo ""
echo "Register response:"
echo "$response_body" | python3 -m json.tool 2>/dev/null || echo "$response_body"
echo "Status: $status_code"

if [ "$status_code" == "201" ]; then
    print_success "User created successfully"
    USER_CREATED=true
elif [ "$status_code" == "409" ]; then
    print_info "User already exists (this is OK for testing)"
    USER_CREATED=true
else
    print_error "Failed to create user"
    USER_CREATED=false
fi

# 5. Test login
print_step "5. Test login..."

login_data='{
    "email": "testuser@example.com", 
    "password": "testpassword123"
}'

echo "Testing login với data:"
echo "$login_data" | python3 -m json.tool

login_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_data")

status_code=$(echo "$login_response" | tail -1)
response_body=$(echo "$login_response" | head -1)

echo ""
echo "Login response:"
echo "$response_body" | python3 -m json.tool 2>/dev/null || echo "$response_body"
echo "Status: $status_code"

# Phân tích kết quả login
if [ "$status_code" == "200" ]; then
    print_success "LOGIN THÀNH CÔNG!"
    
    # Extract access token
    access_token=$(echo "$response_body" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('access_token', 'NOT_FOUND'))
except:
    print('PARSE_ERROR')
")
    
    if [ "$access_token" != "NOT_FOUND" ] && [ "$access_token" != "PARSE_ERROR" ]; then
        print_success "Access token received"
        
        # Test protected endpoint
        print_step "6. Test protected endpoint..."
        protected_response=$(curl -s -w "\n%{http_code}" -X GET "$BACKEND_URL/api/auth/protected" \
            -H "Authorization: Bearer $access_token")
        
        protected_status=$(echo "$protected_response" | tail -1)
        protected_body=$(echo "$protected_response" | head -1)
        
        echo "Protected endpoint response:"
        echo "$protected_body" | python3 -m json.tool 2>/dev/null || echo "$protected_body"
        echo "Status: $protected_status"
        
        if [ "$protected_status" == "200" ]; then
            print_success "Protected endpoint works"
        else
            print_error "Protected endpoint failed"
        fi
    fi
    
elif [ "$status_code" == "401" ]; then
    print_error "LOGIN FAILED: Invalid credentials"
    
elif [ "$status_code" == "402" ]; then
    print_error "LOGIN FAILED: User not active or team issues"
    print_warning "LÝ DO CHÍNH: User cần có team_id và team phải tồn tại"
    echo ""
    print_info "Giải pháp:"
    echo "1. Tạo team trước"
    echo "2. Assign user vào team" 
    echo "3. Hoặc bỏ logic kiểm tra team (development)"
    
elif [ "$status_code" == "400" ]; then
    print_error "LOGIN FAILED: Missing required fields"
    
elif [ "$status_code" == "500" ]; then
    print_error "LOGIN FAILED: Server error (likely MongoDB issue)"
    
else
    print_error "LOGIN FAILED: Unknown error (Status: $status_code)"
fi

# 6. Kiểm tra database collections
print_step "7. Database diagnosis..."
if docker ps | grep -q ecom_mongodb; then
    print_info "MongoDB container đang chạy"
    
    # Kiểm tra collections
    echo ""
    print_info "Checking database collections..."
    
    # List databases
    docker exec ecom_mongodb mongosh --quiet --eval "
        show dbs
    " 2>/dev/null || docker exec ecom_mongodb mongo --quiet --eval "
        show dbs
    " 2>/dev/null
    
    # Check users collection
    echo ""
    print_info "Checking users collection..."
    docker exec ecom_mongodb mongosh --quiet --eval "
        use exp_ecom_db
        db.users.countDocuments()
    " 2>/dev/null || docker exec ecom_mongodb mongo --quiet --eval "
        use exp_ecom_db
        db.users.count()
    " 2>/dev/null
    
    # Check teams collection  
    echo ""
    print_info "Checking teams collection..."
    docker exec ecom_mongodb mongosh --quiet --eval "
        use exp_ecom_db
        db.teams.countDocuments()
    " 2>/dev/null || docker exec ecom_mongodb mongo --quiet --eval "
        use exp_ecom_db
        db.teams.count()
    " 2>/dev/null
    
else
    print_warning "MongoDB container không chạy"
fi

# 7. Kết luận và đề xuất
echo ""
echo "=========================================="
print_step "🎯 CONCLUSION & RECOMMENDATIONS"
echo "=========================================="

if [ "$status_code" == "402" ]; then
    echo ""
    print_error "VẤN ĐỀ CHÍNH: USER AUTHENTICATION CẦN TEAM_ID"
    echo ""
    print_info "Backend yêu cầu:"
    echo "  • User phải có team_id"
    echo "  • Team phải tồn tại trong database"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Tạo team trong database"
    echo "  2️⃣ Assign user vào team"
    echo "  3️⃣ Hoặc tạm thời bỏ check team (dev mode)"
    
elif [ "$status_code" == "500" ]; then
    print_error "VẤN ĐỀ CHÍNH: MONGODB CONNECTION"
    echo ""
    print_warning "GIẢI PHÁP:"
    echo "  1️⃣ Fix MongoDB: ./fix-mongodb.sh"
    echo "  2️⃣ Restart backend: ./start-backend-simple.sh"
    
elif [ "$status_code" == "200" ]; then
    print_success "LOGIN HOẠT ĐỘNG BÌNH THƯỜNG!"
    echo ""
    print_info "Có thể vấn đề ở:"
    echo "  • Frontend không gửi đúng request"
    echo "  • CORS issues"
    echo "  • URL không đúng"
    
else
    print_warning "VẤN ĐỀ KHÔNG XÁC ĐỊNH"
    echo ""
    print_info "Cần kiểm tra thêm:"
    echo "  • Backend logs: docker logs ecom_backend"
    echo "  • Frontend console errors"
    echo "  • Network requests trong browser"
fi

echo ""
print_info "📋 Next steps để fix login:"
echo "  ./fix-login-team-issue.sh   # Tạo team và assign user"
echo "  ./disable-team-check.sh     # Tạm bỏ check team (dev)"
echo "  ./check-frontend-login.sh   # Debug frontend login" 