#!/bin/bash

# Script tạm thời disable team check trong auth.py cho development
echo "🔧 DISABLING TEAM CHECK FOR DEVELOPMENT"
echo "======================================="

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

# Backup original auth.py
print_step "1. Backup original auth.py..."
if [ ! -f "backend/app/routes/auth.py.backup" ]; then
    cp backend/app/routes/auth.py backend/app/routes/auth.py.backup
    print_success "Backup created: auth.py.backup"
else
    print_info "Backup already exists"
fi

# Modify auth.py to disable team check
print_step "2. Modifying auth.py to disable team check..."

# Tạo auth.py modified
cat > backend/app/routes/auth_modified.py << 'EOF'
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from datetime import timedelta
from app import mongo, jwt, bcrypt
import logging
from bson import ObjectId

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        logger.debug(f"Register attempt with data: {data}")
        
        # Check if required fields exist
        if not all(k in data for k in ['email', 'password', 'username']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Check if user already exists
        if mongo.db.users.find_one({'email': data['email']}):
            return jsonify({'error': 'Email already registered'}), 409
        
        # Hash password with specific rounds
        try:
            hashed_password = bcrypt.generate_password_hash(data['password'], rounds=12).decode('utf-8')
            logger.debug("Password hashed successfully")
        except Exception as e:
            logger.error(f"Password hashing error: {str(e)}")
            return jsonify({'error': 'Error hashing password'}), 500
        
        # Create new user
        new_user = {
            'email': data['email'],
            'password': hashed_password,
            'username': data['username'],
            'role': 'user'  # Default role
        }
        
        mongo.db.users.insert_one(new_user)
        logger.debug("User registered successfully")
        
        return jsonify({'message': 'User registered successfully'}), 201
        
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        logger.debug(f"Login attempt with data: {data}")
        
        # Check if required fields exist
        if not all(k in data for k in ['email', 'password']):
            logger.debug("Missing email or password")
            return jsonify({'error': 'Missing email or password'}), 400
        
        # Find user by email or username
        user = mongo.db.users.find_one({
            '$or': [
                {'email': data['email']},
                {'username': data['email']}
            ]
        })
            
        if not user:
            logger.debug("User not found")
            return jsonify({'error': 'Invalid email or username'}), 401
            
        # Get stored password and check
        stored_password = user['password']
        input_password = data['password']
        
        # Debug log
        logger.debug(f"Stored password hash: {stored_password}")
        logger.debug(f"Input password: {input_password}")
        
        is_valid = bcrypt.check_password_hash(stored_password, input_password)
        logger.debug(f"Password validation result: {is_valid}")
        
        if not is_valid:
            logger.debug("Invalid password")
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Create tokens
        access_token = create_access_token(
            identity=str(user['_id']),
            expires_delta=timedelta(hours=24)
        )
        refresh_token = create_refresh_token(
            identity=str(user['_id']),
            expires_delta=timedelta(days=30)
        )

        # ===== TEAM CHECK DISABLED FOR DEVELOPMENT =====
        # Original code (commented out):
        # Check if user has team_id
        # if not user.get('team_id'):
        #     return jsonify({'error': 'User is not active. Please contact administrator.'}), 402
        # my_team = mongo.db.teams.find_one({'_id': ObjectId(user['team_id'])})
        # if not my_team:
        #     return jsonify({'error': 'User team not found. Please contact administrator.'}), 402
        
        # Development mode: Create fake team data if not exists
        team_name = "Development Team"
        if user.get('team_id'):
            my_team = mongo.db.teams.find_one({'_id': ObjectId(user['team_id'])})
            if my_team:
                team_name = my_team.get('name', 'Development Team')
        # ===============================================

        user_response = {
            'access_token': access_token,
            'refresh_token': refresh_token,
            'id': str(user['_id']),
            'email': user['email'],
            'name': user.get('username', ''),
            'username': user.get('username', ''),
            'role': user.get('role', 'user'),
            'picture': user.get('avatar', ''),
            'team_id': str(user.get('team_id', '')),
            'token_user': user.get('token_user', ''),
            'team_name': team_name
        }
        
        if user.get('role') == 'admin':
            teams = mongo.db.teams.find()
            teams_list = []
            for team in teams:
                team['_id'] = str(team['_id'])
                if team['_id'] == user_response['team_id']:
                    user_response['team_name'] = team.get('name', '')
                teams_list.append(team)
            user_response['teams'] = teams_list
            
        return jsonify(user_response), 200
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    try:
        current_user = get_jwt_identity()
        access_token = create_access_token(identity=current_user)
        return jsonify({'access_token': access_token}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    current_user = get_jwt_identity()
    user = mongo.db.users.find_one({'_id': current_user})
    return jsonify({'logged_in_as': user['email']}), 200 

@auth_bp.route('/get-users', methods=['GET'])
def getusers():
    users = mongo.db.teamexp_users.find()
    users_list = []
    for user in users:
        user['_id'] = str(user['_id'])
        users_list.append(user)
    return jsonify(users_list), 200

@auth_bp.route('/get-user', methods=['GET'])
def getuser():
    try:
        current_user = get_jwt_identity()
        user = mongo.db.teamexp_users.find_one({'_id': current_user})
        if user:
            user['_id'] = str(user['_id'])
            access_token = create_access_token(identity=str(user['_id']))
            refresh_token = create_refresh_token(identity=str(user['_id']))
            user['access_token'] = access_token
            user['refresh_token'] = refresh_token
            return jsonify(user), 200
        return jsonify({'error': 'User not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
EOF

print_success "Modified auth.py created"

# Replace original with modified
print_step "3. Applying team check disable..."
cp backend/app/routes/auth_modified.py backend/app/routes/auth.py
rm backend/app/routes/auth_modified.py
print_success "Team check disabled in auth.py"

# Restart backend nếu đang chạy
print_step "4. Restarting backend to apply changes..."
if docker ps | grep -q ecom_backend; then
    print_info "Restarting backend container..."
    docker restart ecom_backend
    sleep 5
    print_success "Backend restarted"
else
    print_warning "Backend container không chạy"
    print_info "Khởi động backend: ./start-backend-simple.sh"
fi

# Test login sau khi disable team check
print_step "5. Testing login sau khi disable team check..."

BACKEND_URL="http://localhost:5000"

# Đợi backend ready
for i in {1..15}; do
    if curl -s "$BACKEND_URL" > /dev/null 2>&1; then
        break
    fi
    echo "⏳ Waiting for backend... ($i/15)"
    sleep 2
done

# Test register và login
test_user='{
    "email": "devuser@example.com",
    "password": "devpassword123",
    "username": "devuser"
}'

# Register user
print_info "Creating test user..."
register_response=$(curl -s -w "\n%{http_code}" -X POST "$BACKEND_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "$test_user")

register_status=$(echo "$register_response" | tail -1)
if [ "$register_status" == "201" ]; then
    print_info "Test user created"
elif [ "$register_status" == "409" ]; then
    print_info "Test user already exists"
fi

# Test login
login_data='{
    "email": "devuser@example.com",
    "password": "devpassword123"
}'

print_info "Testing login..."
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
    print_success "🎉 LOGIN WORKS WITHOUT TEAM CHECK!"
    
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
else
    print_error "Login vẫn failed với status: $login_status"
fi

echo ""
echo "=========================================="
print_step "🎯 SUMMARY"
echo "=========================================="

print_warning "⚠️ TEAM CHECK DISABLED FOR DEVELOPMENT"
print_success "✅ Original auth.py backed up to auth.py.backup"
print_success "✅ Modified auth.py applied"

if [ "$login_status" == "200" ]; then
    print_success "✅ Login test PASSED"
    echo ""
    print_info "🎉 PROBLEM SOLVED!"
    echo ""
    print_warning "📋 Notes:"
    echo "  • Team check disabled - users can login without team"
    echo "  • This is for DEVELOPMENT only"
    echo "  • Team name defaults to 'Development Team'"
    
else
    print_error "❌ Login vẫn failed"
    print_info "Cần debug thêm: ./debug-login.sh"
fi

echo ""
print_warning "🔄 To restore original team check:"
echo "  ./restore-team-check.sh"

echo ""
print_info "📋 Next steps:"
echo "  1. Test login từ frontend"
echo "  2. Develop các features khác"
echo "  3. Restore team check khi deploy production"

echo ""
print_info "🛠️ Useful commands:"
echo "  docker logs ecom_backend                # Backend logs"
echo "  curl http://localhost:5000/api/auth/login -X POST -H 'Content-Type: application/json' -d '$login_data'" 