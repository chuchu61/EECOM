#!/bin/bash

echo "🔧 CREATING FRONTEND .env.local"

# Chuyển vào frontend directory
cd frontend

# Tạo .env.local file
cat > .env.local << 'ENVEOF'
NEXT_PUBLIC_API_URL=http://localhost:5000
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key-here
ENVEOF

echo "✅ .env.local created in frontend directory"
echo "📁 File location: frontend/.env.local"
echo ""
echo "Contents:"
cat .env.local

