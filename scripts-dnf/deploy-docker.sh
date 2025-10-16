#!/bin/bash

set -e

# 프로젝트 루트 디렉토리로 이동 (scripts-dnf의 상위 디렉토리)
cd "$(dirname "$0")/.."

echo "🚀 Starting Hono app Docker Compose deployment..."

# 1. Pull latest code
echo "📥 Pulling latest code from git..."
git pull origin main

# 2. Stop existing containers
echo "🛑 Stopping existing containers..."
docker compose down --remove-orphans

# 3. Rebuild and restart containers with Bun
echo "🔨 Building new image and starting containers..."
docker compose up -d --build

# 4. Wait for container to be healthy
echo "⏳ Waiting for Hono app container to be healthy..."
sleep 5

# 5. Check status
echo "📊 Container status:"
docker compose ps

# 6. Show recent logs
echo ""
echo "📝 Recent logs:"
docker compose logs --tail 10

echo ""
echo "✅ Hono app deployment completed successfully!"
