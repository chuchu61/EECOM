#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running in correct directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "Please run this script from the project root directory (where docker-compose.yml is located)"
    exit 1
fi

print_status "🚀 Starting complete setup for ecom backend + MongoDB..."

# Step 1: Clean up existing containers and networks
print_status "🧹 Cleaning up existing containers and networks..."
docker stop ecom_backend ecom_mongodb ecom_frontend 2>/dev/null || true
docker rm ecom_backend ecom_mongodb ecom_frontend 2>/dev/null || true
docker network rm ecom_network 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

# Kill any processes using our ports
print_status "🔌 Checking and freeing up ports 5000 and 27017..."
lsof -ti:5000 | xargs kill -9 2>/dev/null || true
lsof -ti:27017 | xargs kill -9 2>/dev/null || true

# Step 2: Create proper .env file
print_status "📝 Creating .env configuration file..."
cd backend
cat > .env << 'EOF'
JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
MONGO_URI=mongodb://localhost:27017/exp_ecom_db
TESTING=False

AWS_BUCKET_NAME=ecom.sys
AWS_ACCESS_KEY_ID=fake_access_key_for_local_dev
AWS_SECRET_ACCESS_KEY=fake_secret_key_for_local_dev
AWS_DEFAULT_REGION=us-east-1
EOF

print_success "✅ .env file created successfully"

# Step 3: Setup virtual environment
print_status "🐍 Setting up clean Python virtual environment..."
rm -rf venv venv_clean venv_new 2>/dev/null || true

python3 -m venv venv_production
source venv_production/bin/activate

# Upgrade pip and essential tools
print_status "⬆️ Upgrading pip and essential tools..."
pip install --upgrade pip setuptools wheel

# Step 4: Install dependencies with error handling
print_status "📦 Installing Python dependencies..."
pip install --no-cache-dir -r requirements.txt

if [ $? -ne 0 ]; then
    print_warning "⚠️ Some packages failed, trying individual installation..."
    pip install flask==2.3.3 flask-cors==4.0.0 pymongo==4.5.0 python-dotenv==1.0.0
    pip install flask-bcrypt==1.0.1 flask-jwt-extended==4.5.2 flask-pymongo==2.3.0
    pip install boto3==1.28.38 humanize==4.8.0 requests==2.32.3
    pip install bcrypt==4.0.1 passlib==1.7.4 python-jose==3.3.0
    pip install Pillow==10.0.0 numpy==1.24.3 pandas==2.2.2 openpyxl==3.1.2
fi

print_success "✅ Python dependencies installed"

# Step 5: Fix AWS service to prevent crashes
print_status "🔧 Fixing AWS service configuration..."
cd ..

# Step 6: Start MongoDB container
print_status "🍃 Starting MongoDB container..."
docker run -d \
  --name ecom_mongodb \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  -e MONGO_INITDB_DATABASE=exp_ecom_db \
  --restart unless-stopped \
  mongo:latest

# Wait for MongoDB to start
print_status "⏳ Waiting for MongoDB to initialize..."
sleep 10

# Check if MongoDB is running
if docker ps | grep -q ecom_mongodb; then
    print_success "✅ MongoDB container started successfully"
else
    print_error "❌ Failed to start MongoDB container"
    exit 1
fi

# Test MongoDB connection
print_status "🔍 Testing MongoDB connection..."
for i in {1..30}; do
    if docker exec ecom_mongodb mongosh --eval "db.runCommand('ping')" >/dev/null 2>&1; then
        print_success "✅ MongoDB is ready and accepting connections"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "❌ MongoDB failed to start properly"
        docker logs ecom_mongodb
        exit 1
    fi
    sleep 2
done

# Step 7: Start backend
print_status "🚀 Starting backend server..."
cd backend
source venv_production/bin/activate

# Create startup script for backend
cat > start_backend_safe.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
import logging
from dotenv import load_dotenv

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

# Load environment variables
load_dotenv()

print("🔧 Environment variables loaded:")
print(f"   MONGO_URI: {os.getenv('MONGO_URI')}")
print(f"   AWS_DEFAULT_REGION: {os.getenv('AWS_DEFAULT_REGION')}")
print(f"   JWT_SECRET_KEY: {'***' if os.getenv('JWT_SECRET_KEY') else 'NOT SET'}")

try:
    # Import Flask app
    from app import app
    print("✅ Flask app imported successfully")
    
    # Check MongoDB URI
    mongo_uri = os.getenv('MONGO_URI', 'mongodb://localhost:27017/exp_ecom_db')
    print(f"🔗 MongoDB URI: {mongo_uri}")
    
    # Start server
    print("🚀 Starting backend server on http://localhost:5000")
    print("📝 You can access the API at: http://localhost:5000")
    print("🛑 Press Ctrl+C to stop the server")
    print("=" * 50)
    
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print(f"Current directory: {current_dir}")
    print(f"Python path: {sys.path}")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ Error starting server: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

# Step 8: Final checks
print_status "🔍 Running final system checks..."

# Check if required ports are available
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_error "❌ Port 5000 is already in use. Please stop the process using this port."
    lsof -i :5000
    exit 1
fi

# Check virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "❌ Virtual environment not activated"
    exit 1
fi

# Check required Python packages
python -c "import flask, pymongo, humanize" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "❌ Required Python packages not installed properly"
    exit 1
fi

print_success "✅ All system checks passed!"

# Step 9: Display summary
print_success "🎉 Setup completed successfully!"
echo ""
echo "📋 Summary:"
echo "  🍃 MongoDB: Running on port 27017"
echo "  🐍 Python virtual environment: Activated"
echo "  📦 Dependencies: Installed"
echo "  ⚙️  Configuration: Ready"
echo ""
echo "🚀 Starting backend server..."
echo "   Backend will be available at: http://localhost:5000"
echo "   MongoDB is available at: localhost:27017"
echo ""
echo "🛑 To stop:"
echo "   - Backend: Press Ctrl+C"
echo "   - MongoDB: docker stop ecom_mongodb"
echo ""

# Start the backend server
python start_backend_safe.py 