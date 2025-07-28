#!/bin/bash

echo "🔧 FIXING AWS BACKEND ISSUE"

# 1. Update .env with AWS config
cat > backend/.env << 'ENVEOF'
MONGO_URI=mongodb://localhost:27017/exp_ecom_db
JWT_SECRET_KEY=Zx8uQmN5tP2LrX7VjA3YwK9oR6dT1sF0
FLASK_ENV=development
PYTHONUNBUFFERED=1
TESTING=False
AWS_BUCKET_NAME=ecom.sys
AWS_ACCESS_KEY_ID=dummy-key
AWS_SECRET_ACCESS_KEY=dummy-secret
AWS_DEFAULT_REGION=us-east-1
DATABASE_TYPE=mongodb
FORCE_MONGODB=true
ENVEOF

# 2. Comment out problematic AWS initialization
sed -i '128,134s/^/# /' backend/app/services/aws_service.py

# 3. Restart backend
docker stop ecom_backend 2>/dev/null || true
docker rm ecom_backend 2>/dev/null || true

cd backend && docker build -t ecom_backend_img . && cd ..

docker run -d \
  --name ecom_backend \
  --network ecom_network \
  -p 5000:5000 \
  --env-file backend/.env \
  -v "$(pwd)/backend:/app" \
  ecom_backend_img

echo "✅ Backend restarted, waiting..."
sleep 15

curl http://localhost:5000/health
