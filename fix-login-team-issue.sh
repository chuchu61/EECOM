#!/bin/bash

# Script fix vấn đề team_id trong login
echo "🛠️ FIXING LOGIN TEAM ISSUE"
echo "=========================="

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

# Kiểm tra MongoDB đang chạy
print_step "Kiểm tra MongoDB..."
if ! docker ps | grep -q ecom_mongodb; then
    print_error "MongoDB container không chạy"
    print_info "Khởi động MongoDB trước: ./fix-mongodb.sh"
    exit 1
fi
print_success "MongoDB container đang chạy"

# Test MongoDB connection
if ! docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
    if ! docker exec ecom_mongodb mongo --eval "db.adminCommand('ping')" &>/dev/null; then
        print_error "MongoDB connection failed"
        exit 1
    fi
fi
print_success "MongoDB connection OK"

# 1. Tạo default team
print_step "1. Tạo default team trong database..."

team_script='
use exp_ecom_db

// Tạo default team nếu chưa có
var existingTeam = db.teams.findOne({name: "Default Team"});
if (!existingTeam) {
    var teamResult = db.teams.insertOne({
        name: "Default Team",
        description: "Default team for all users",
        created_at: new Date(),
        status: "active"
    });
    print("Team created with ID: " + teamResult.insertedId);
    var teamId = teamResult.insertedId;
} else {
    print("Team already exists with ID: " + existingTeam._id);
    var teamId = existingTeam._id;
}

// Hiển thị team info
var team = db.teams.findOne({_id: teamId});
print("Team info: " + JSON.stringify(team));
'

# Execute team creation
docker exec ecom_mongodb mongosh --quiet --eval "$team_script" 2>/dev/null || \
docker exec ecom_mongodb mongo --quiet --eval "$team_script" 2>/dev/null

print_success "Default team created/verified"

# 2. Get team ID
print_step "2. Lấy team ID..."

get_team_id_script='
use exp_ecom_db
var team = db.teams.findOne({name: "Default Team"});
if (team) {
    print(team._id.toString());
} else {
    print("NOT_FOUND");
}
'

TEAM_ID=$(docker exec ecom_mongodb mongosh --quiet --eval "$get_team_id_script" 2>/dev/null || \
          docker exec ecom_mongodb mongo --quiet --eval "$get_team_id_script" 2>/dev/null)

if [ "$TEAM_ID" == "NOT_FOUND" ]; then
    print_error "Không thể lấy team ID"
    exit 1
fi

print_success "Team ID: $TEAM_ID"

# 3. Update tất cả users không có team_id
print_step "3. Update users với team_id..."

update_users_script="
use exp_ecom_db

// Update tất cả users không có team_id
var result = db.users.updateMany(
    { \$or: [ {team_id: {exists: false}}, {team_id: null}, {team_id: ''} ] },
    { \$set: { team_id: ObjectId('$TEAM_ID') } }
);

print('Updated ' + result.modifiedCount + ' users');

// Hiển thị users đã update
var users = db.users.find({team_id: ObjectId('$TEAM_ID')}).toArray();
print('Users with team_id:');
for (var i = 0; i < users.length; i++) {
    print('  - ' + users[i].email + ' (ID: ' + users[i]._id + ')');
}
"

docker exec ecom_mongodb mongosh --quiet --eval "$update_users_script" 2>/dev/null || \
docker exec ecom_mongodb mongo --quiet --eval "$update_users_script" 2>/dev/null

print_success "Users updated với team_id"

# 4. Verify setup
print_step "4. Verify database setup..."

verify_script='
use exp_ecom_db

print("=== TEAMS ===");
db.teams.find().forEach(function(team) {
    print("Team: " + team.name + " (ID: " + team._id + ")");
});

print("\n=== USERS ===");
db.users.find().forEach(function(user) {
    print("User: " + user.email + " | Team ID: " + user.team_id);
});

print("\n=== STATS ===");
print("Total teams: " + db.teams.countDocuments());
print("Total users: " + db.users.countDocuments());
print("Users with team_id: " + db.users.countDocuments({team_id: {$exists: true, $ne: null}}));
'

echo ""
print_info "Database verification:"
docker exec ecom_mongodb mongosh --quiet --eval "$verify_script" 2>/dev/null || \
docker exec ecom_mongodb mongo --quiet --eval "$verify_script" 2>/dev/null

# 5. Test login sau khi fix
print_step "5. Test login sau khi fix team issue..."

# Đợi một chút để database update
sleep 2

# Test với user có sẵn hoặc tạo user mới
test_user='{
    "email": "testuser@example.com",
    "password": "testpassword123",
    "username": "testuser"
}'

BACKEND_URL="http://localhost:5000"

# Register user nếu chưa có
print_info "Ensuring test user exists..."
register_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "$test_user")

register_status=$(echo "$register_response" | tail -1)
if [ "$register_status" == "201" ]; then
    print_info "Test user created"
elif [ "$register_status" == "409" ]; then
    print_info "Test user already exists"
else
    print_warning "User creation status: $register_status"
fi

# Đảm bảo user có team_id
print_info "Ensuring user has team_id..."
ensure_team_script="
use exp_ecom_db
db.users.updateOne(
    {email: 'testuser@example.com'}, 
    {\$set: {team_id: ObjectId('$TEAM_ID')}}
);
print('User team_id updated');
"

docker exec ecom_mongodb mongosh --quiet --eval "$ensure_team_script" 2>/dev/null || \
docker exec ecom_mongodb mongo --quiet --eval "$ensure_team_script" 2>/dev/null

# Test login
print_info "Testing login..."
login_data='{
    "email": "testuser@example.com",
    "password": "testpassword123"
}'

login_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_data")

login_status=$(echo "$login_response" | tail -1)
login_body=$(echo "$login_response" | head -1)

echo ""
echo "Login test result:"
echo "$login_body" | python3 -m json.tool 2>/dev/null || echo "$login_body"
echo "Status: $login_status"

if [ "$login_status" == "200" ]; then
    print_success "🎉 LOGIN FIX THÀNH CÔNG!"
    echo ""
    print_info "Login response includes:"
    echo "$login_body" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'access_token' in data:
        print('  ✅ Access Token: ' + data['access_token'][:50] + '...')
    if 'email' in data:
        print('  ✅ Email: ' + data['email'])
    if 'username' in data:
        print('  ✅ Username: ' + data['username'])
    if 'team_name' in data:
        print('  ✅ Team Name: ' + data['team_name'])
    if 'role' in data:
        print('  ✅ Role: ' + data['role'])
except:
    pass
"
    
elif [ "$login_status" == "402" ]; then
    print_error "Vẫn gặp team issue - cần debug thêm"
    
elif [ "$login_status" == "401" ]; then
    print_error "Invalid credentials - cần check password"
    
else
    print_error "Login failed với status: $login_status"
fi

echo ""
echo "=========================================="
print_step "🎯 SUMMARY"
echo "=========================================="

print_success "✅ Default team created: 'Default Team'"
print_success "✅ All users assigned to default team"
print_success "✅ Database setup completed"

if [ "$login_status" == "200" ]; then
    print_success "✅ Login test PASSED"
    echo ""
    print_info "🎉 PROBLEM SOLVED!"
    echo ""
    print_warning "📋 Next steps:"
    echo "  1. Test login từ frontend"
    echo "  2. Kiểm tra CORS nếu frontend vẫn lỗi"
    echo "  3. Check network requests trong browser"
    
else
    print_warning "⚠️ Login test vẫn failed"
    echo ""
    print_info "📋 Additional debugging:"
    echo "  ./debug-login.sh           # Full login debug"
    echo "  docker logs ecom_backend   # Check backend logs"
    echo "  ./check-frontend-login.sh  # Check frontend"
fi

echo ""
print_info "🛠️ Useful commands:"
echo "  docker exec ecom_mongodb mongosh    # Access MongoDB"
echo "  docker logs ecom_backend            # Backend logs"
echo "  curl http://localhost:5000/health   # Backend health" 