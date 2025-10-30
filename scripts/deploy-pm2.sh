#!/bin/bash

# 프로젝트 루트 디렉토리로 이동 (scripts의 상위 디렉토리)
cd "$(dirname "$0")/.."

echo "🚀 Starting Hono app deployment with Bun..."

# 1. Pull latest code
echo "📥 Pulling latest code from git..."
git pull origin main

# 2. Install dependencies with Bun
echo "📦 Installing dependencies with Bun..."
bun install --frozen-lockfile

# 3. Build TypeScript with Bun
echo "🔨 Building TypeScript with Bun..."
bun run build

# 4. Reload PM2 (zero-downtime)
echo "♻️  Reloading PM2 processes..."
pm2 reload ecosystem.config.js --update-env

# 5. Wait for app to be ready
echo "⏳ Waiting for app to be ready..."
sleep 3

# 6. Health check
echo "🏥 Running health check..."
MAX_RETRIES=10
RETRY_COUNT=0
HEALTH_URL="http://localhost:4000/health"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
    echo "✅ Health check passed!"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "   Retry $RETRY_COUNT/$MAX_RETRIES..."
  sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Health check failed after $MAX_RETRIES attempts!"
  echo "📝 Recent logs:"
  pm2 logs --lines 20 --nostream
  exit 1
fi

# 7. Show status
echo ""
echo "✅ Deployment complete!"
pm2 status
echo ""
echo "📝 Recent logs:"
pm2 logs --lines 10 --nostream
