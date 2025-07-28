#!/bin/bash

echo "🔍 CHECKING MONGODB USERS"
echo "========================="

# Check if MongoDB is running
if ! docker ps | grep -q ecom_mongodb; then
    echo "❌ MongoDB container not running"
    echo "Start with: docker start ecom_mongodb"
    exit 1
fi

# Check MongoDB connection
if ! docker exec ecom_mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
    echo "❌ MongoDB connection failed"
    exit 1
fi

echo "✅ MongoDB is running and accessible"
echo ""

# Get users info
echo "=== USERS INFORMATION ==="
docker exec ecom_mongodb mongosh --quiet --eval "
use exp_ecom_db;

var userCount = db.users.countDocuments();
print('📊 Total users in database:', userCount);

if (userCount > 0) {
    print('\\n👥 User List:');
    print('================');
    
    db.users.find({}, {email:1, username:1, role:1, team_id:1, _id:0}).forEach(function(user, index) {
        print((index + 1) + '. Email: ' + user.email);
        print('   Username: ' + (user.username || 'N/A'));
        print('   Role: ' + (user.role || 'user'));
        print('   Team ID: ' + (user.team_id || 'None'));
        print('   ---');
    });
    
    print('\\n🔐 Password Information:');
    print('========================');
    var sampleUser = db.users.findOne({}, {email:1, password:1});
    if (sampleUser && sampleUser.password) {
        print('✅ Passwords are hashed');
        print('Hash type: ' + (sampleUser.password.startsWith('\$2b\$') ? 'bcrypt (✅ secure)' : 'unknown'));
        print('Sample hash: ' + sampleUser.password.substring(0, 20) + '...');
    } else {
        print('❌ No password found or passwords not hashed');
    }
} else {
    print('❌ No users found in database');
    print('');
    print('💡 To create a test user:');
    print('curl -X POST http://localhost:5000/api/auth/register \\');
    print('  -H \"Content-Type: application/json\" \\');
    print('  -d \"{\\\"email\\\":\\\"test@example.com\\\",\\\"password\\\":\\\"test123\\\",\\\"username\\\":\\\"testuser\\\"}\"');
}
"

# Check teams
echo ""
echo "=== TEAMS INFORMATION ==="
docker exec ecom_mongodb mongosh --quiet --eval "
use exp_ecom_db;

var teamCount = db.teams.countDocuments();
print('📊 Total teams in database:', teamCount);

if (teamCount > 0) {
    print('\\n🏢 Team List:');
    print('==============');
    db.teams.find({}, {name:1, _id:1}).forEach(function(team, index) {
        print((index + 1) + '. Name: ' + team.name);
        print('   ID: ' + team._id);
        print('   ---');
    });
} else {
    print('❌ No teams found');
    print('💡 Users need teams to login successfully');
}
"

echo ""
echo "🎯 SUMMARY"
echo "=========="
echo "Database: exp_ecom_db"
echo "Collections checked: users, teams"
echo ""
echo "💡 Common login credentials to try:"
echo "If you see users above, use their email with the password you set when creating them"

