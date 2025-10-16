#!/bin/bash

# 프로젝트 루트 디렉토리로 이동 (scripts의 상위 디렉토리)
cd "$(dirname "$0")/.."

echo "📥 Pulling latest code from git..."
git pull origin main