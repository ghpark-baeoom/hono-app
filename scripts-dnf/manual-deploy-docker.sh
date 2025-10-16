#!/bin/bash

set -e

# 프로젝트 루트 디렉토리로 이동 (scripts-dnf의 상위 디렉토리)
cd "$(dirname "$0")/.."

echo "🚀 Starting Hono app Docker Compose deployment..."

# 1. Pull latest code
echo "📥 Pulling latest code from git..."
git pull origin main

# 2. Rebuild and restart containers with Bun (zero-downtime)
echo "🔨 Building new Hono app image with Bun and restarting containers..."
docker compose up -d --build --no-deps

# 3. Wait for container to be healthy
echo "⏳ Waiting for Hono app container to be healthy..."
sleep 5

# 4. Check status
echo "📊 Container status:"
docker compose ps

# 5. Show recent logs
echo ""
echo "📝 Recent logs:"
docker compose logs --tail 10

echo ""
echo "✅ Hono app deployment completed successfully!"
