#!/bin/bash

set -e

# 프로젝트 루트 디렉토리로 이동
cd "$(dirname "$0")/.."

echo "🚀 Setting up PM2 auto-startup on server reboot..."
echo ""

# 1. 현재 PM2 상태 확인
echo "📊 Current PM2 status:"
pm2 status || true
echo ""

# 2. 프로세스 목록 저장
echo "💾 Saving current PM2 process list..."
pm2 save
echo ""

# 3. PM2 startup 명령어 생성
echo "🔧 Generating PM2 startup script..."
echo ""
echo "⚠️  IMPORTANT: The next command will output a 'sudo' command."
echo "   You MUST copy and paste that sudo command and run it!"
echo ""
echo "Press Enter to continue..."
read

pm2 startup

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 NEXT STEPS:"
echo ""
echo "1. Copy the 'sudo env PATH=...' command shown above"
echo "2. Paste and run it in your terminal"
echo "3. Run this script again OR manually run: pm2 save"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After completing these steps, your PM2 processes will"
echo "automatically start after server reboot!"
echo ""
echo "Test it with: sudo reboot"
