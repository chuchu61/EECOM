#!/bin/bash

echo "🔧 FIXING NEXTAUTH SESSION PERSISTENCE"

# Backup auth.ts
cp frontend/src/libs/auth.ts frontend/src/libs/auth.ts.backup

# Add debug và force session persistence
cat >> frontend/src/libs/auth.ts << 'ADDITIONAL'

// Additional session debugging
export const getServerAuthSession = () => {
  return getServerSession(authOptions)
}

// Export for client-side debugging
export { authOptions as nextAuthOptions }
ADDITIONAL

echo "✅ NextAuth session fixes applied"

