#!/bin/bash

echo "🔧 FIXING MONGODB HEALTH CHECK"

# Backup original file
cp backend/app/__init__.py backend/app/__init__.py.backup

# Fix the health check line
sed -i 's/mongo\.db\.admin\.command/mongo.db.command/' backend/app/__init__.py

# Verify fix
echo "=== FIXED LINE ==="
grep -n "mongo.db.command" backend/app/__init__.py

echo "✅ Health check fixed"
echo "📋 Next: Rebuild and restart backend"

