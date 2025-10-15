#!/bin/bash

# 스크립트가 있는 디렉토리로 이동
cd "$(dirname "$0")"

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
pm2 reload ecosystem.config.cjs

# 5. Show status
echo "✅ Deployment complete!"
pm2 status
pm2 logs --lines 10
