#!/bin/bash

# Script debug backend chi tiết
echo "🔍 DEBUGGING BACKEND ISSUES..."
echo "================================"

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

# 1. Kiểm tra Docker
echo -e "${BLUE}1. CHECKING DOCKER...${NC}"
docker --version
print_status "Docker installed"

docker info > /dev/null 2>&1
print_status "Docker running"

# 2. Kiểm tra containers
echo -e "\n${BLUE}2. CHECKING CONTAINERS...${NC}"
echo "All containers:"
docker ps -a

echo -e "\nEcom containers only:"
docker ps -a | grep ecom

# 3. Kiểm tra services status
echo -e "\n${BLUE}3. DOCKER COMPOSE STATUS...${NC}"
docker-compose ps

# 4. Kiểm tra logs
echo -e "\n${BLUE}4. BACKEND LOGS (last 20 lines)...${NC}"
docker-compose logs --tail=20 backend

echo -e "\n${BLUE}5. MONGODB LOGS (last 10 lines)...${NC}"
docker-compose logs --tail=10 mongodb

# 5. Kiểm tra network
echo -e "\n${BLUE}6. NETWORK TESTING...${NC}"

# Test port binding
echo "Testing port 5000 binding:"
netstat -tulpn | grep :5000 || ss -tulpn | grep :5000
print_status "Port 5000 binding"

# Test container internal network
echo -e "\nTesting container network:"
docker exec ecom_backend ping -c 1 mongodb 2>/dev/null
print_status "Backend can reach MongoDB"

# 6. Test API endpoints từ bên trong container
echo -e "\n${BLUE}7. INTERNAL API TESTING...${NC}"

# Test từ bên trong backend container
echo "Testing from inside backend container:"
docker exec ecom_backend curl -s http://localhost:5000 > /dev/null 2>&1
print_status "Internal API call"

# 7. Test từ host machine
echo -e "\n${BLUE}8. EXTERNAL API TESTING...${NC}"

# Test basic connectivity
echo "Testing basic connectivity:"
curl -s --connect-timeout 5 http://localhost:5000 > /dev/null 2>&1
print_status "Host to container connection"

# Test với verbose output
echo -e "\nTesting với chi tiết:"
curl -v --connect-timeout 10 http://localhost:5000 2>&1 | head -10

# 8. Kiểm tra file configurations
echo -e "\n${BLUE}9. CONFIGURATION CHECK...${NC}"

echo "Backend .env file:"
if [ -f "backend/.env" ]; then
    echo -e "${GREEN}✅ .env exists${NC}"
    echo "Content:"
    cat backend/.env
else
    echo -e "${RED}❌ .env missing${NC}"
fi

echo -e "\nDocker-compose.yml backend section:"
grep -A 20 "backend:" docker-compose.yml

# 9. Health check manual
echo -e "\n${BLUE}10. MANUAL HEALTH CHECK...${NC}"

echo "Container health status:"
docker inspect ecom_backend | grep -A 5 "Health"

echo -e "\nManual health check:"
docker exec ecom_backend curl -f http://localhost:5000/health 2>/dev/null
print_status "Manual health check"

# 10. Troubleshooting recommendations
echo -e "\n${BLUE}11. TROUBLESHOOTING RECOMMENDATIONS...${NC}"

# Check if containers are running
if ! docker ps | grep -q ecom_backend; then
    echo -e "${RED}❌ Backend container not running${NC}"
    echo -e "${YELLOW}💡 Try: docker-compose up -d backend mongodb${NC}"
fi

# Check if port is accessible
if ! curl -s --connect-timeout 5 http://localhost:5000 > /dev/null 2>&1; then
    echo -e "${RED}❌ Backend not accessible from host${NC}"
    echo -e "${YELLOW}💡 Possible solutions:${NC}"
    echo "   1. Check firewall: sudo ufw status"
    echo "   2. Check WSL port forwarding"
    echo "   3. Try different port: http://127.0.0.1:5000"
    echo "   4. Restart containers: docker-compose restart"
fi

# 11. Quick fixes
echo -e "\n${BLUE}12. QUICK FIXES TO TRY...${NC}"
echo "Run these commands one by one:"
echo -e "${YELLOW}"
echo "# Stop everything"
echo "docker-compose down"
echo ""
echo "# Remove old containers" 
echo "docker container prune -f"
echo ""
echo "# Restart Docker (if needed)"
echo "sudo systemctl restart docker"
echo ""
echo "# Start fresh"
echo "docker-compose up -d --build backend mongodb"
echo ""
echo "# Wait and test"
echo "sleep 30 && curl http://localhost:5000"
echo -e "${NC}"

echo -e "\n${GREEN}🎯 DEBUG COMPLETED!${NC}"
echo "If backend still not working, copy the output above for further investigation." 