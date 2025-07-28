#!/bin/bash

# Test script siêu đơn giản cho Python Flask
echo "🧪 TESTING BASIC PYTHON FLASK"
echo "=============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test Python
echo "1. Testing Python..."
python3 --version
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Python3 OK${NC}"
else
    echo -e "${RED}❌ Python3 failed${NC}"
    echo "Install Python: sudo apt install python3 python3-pip -y"
    exit 1
fi

# Test pip
echo -e "\n2. Testing pip..."
python3 -m pip --version
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ pip OK${NC}"
else
    echo -e "${RED}❌ pip failed${NC}"
    echo "Install pip: sudo apt install python3-pip -y"
    exit 1
fi

# Install Flask siêu đơn giản
echo -e "\n3. Installing Flask..."
python3 -m pip install flask --user --quiet
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flask installed${NC}"
else
    echo -e "${RED}❌ Flask install failed${NC}"
    exit 1
fi

# Tạo app siêu đơn giản
echo -e "\n4. Creating ultra-simple app..."
cat > /tmp/ultra_simple_app.py << 'EOF'
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return {
        'message': 'Hello from Ultra Simple Flask!',
        'status': 'working',
        'test': 'success'
    }

@app.route('/test')
def test():
    return {'test': 'This is a test endpoint', 'working': True}

if __name__ == '__main__':
    print("🚀 Starting ultra-simple Flask app...")
    print("📡 Available at: http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

echo -e "${GREEN}✅ Ultra-simple app created${NC}"

# Run app
echo -e "\n5. Starting ultra-simple Flask app..."
echo -e "${YELLOW}⚠️ This will run until you press Ctrl+C${NC}"
echo -e "📡 App will be available at: http://localhost:5000"
echo -e "🧪 Test endpoint: http://localhost:5000/test"
echo ""

python3 /tmp/ultra_simple_app.py 