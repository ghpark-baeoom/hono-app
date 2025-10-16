#!/bin/bash

set -e

# 프로젝트 루트 디렉토리로 이동
cd "$(dirname "$0")/.."

echo "🔍 PM2 + Bun 디버깅 정보 수집"
echo "================================"
echo ""

# 1. PM2 상태
echo "📊 1. PM2 상태:"
pm2 status
echo ""

# 2. 실제 Bun 프로세스 확인
echo "🔍 2. 실제 Bun 프로세스 (ps):"
ps aux | grep -E "bun.*(server|dist)" | grep -v grep || echo "Bun 프로세스를 찾을 수 없음"
echo ""

# 3. 포트 리스닝 확인
echo "🌐 3. 포트 3001 리스닝 상태:"
lsof -i :3001 || echo "포트 3001이 열려있지 않음"
echo ""

# 4. PM2 로그 (마지막 20줄)
echo "📝 4. PM2 로그 (최근 20줄):"
pm2 logs --lines 20 --nostream
echo ""

# 5. Bun 버전
echo "🚀 5. Bun 버전:"
bun --version
echo ""

# 6. Node.js 버전 (PM2용)
echo "📦 6. Node.js 버전 (PM2):"
node --version
echo ""

# 7. 빌드 파일 확인
echo "📁 7. 빌드 파일 존재 여부:"
if [ -f "dist/server.js" ]; then
  echo "✅ dist/server.js 존재"
  echo "   파일 크기: $(du -h dist/server.js | cut -f1)"
  echo "   reusePort 확인:"
  grep -n "reusePort" dist/server.js || echo "   ⚠️  reusePort 설정 없음"
else
  echo "❌ dist/server.js 없음 - 빌드 필요!"
fi
echo ""

# 8. ecosystem.config.cjs 설정 확인
echo "⚙️  8. PM2 설정 확인:"
if [ -f "ecosystem.config.cjs" ]; then
  echo "✅ ecosystem.config.cjs 존재"
  echo "   주요 설정:"
  grep -E "(interpreter|instances|exec_mode)" ecosystem.config.cjs | grep -v "//" || true
else
  echo "❌ ecosystem.config.cjs 없음"
fi
echo ""

# 9. 환경변수 확인
echo "🔧 9. 환경변수:"
echo "   PORT: ${PORT:-3001} (기본값: 3001)"
echo "   NODE_ENV: ${NODE_ENV:-development}"
echo ""

# 10. 시스템 리소스
echo "💻 10. 시스템 리소스:"
echo "   CPU 사용률:"
top -bn1 | grep "Cpu(s)" || true
echo "   메모리 사용률:"
free -h | grep -E "(Mem|Swap)" || true
echo ""

echo "================================"
echo "✅ 디버깅 정보 수집 완료"
echo ""
echo "💡 다음 단계:"
echo "   - PM2 status에서 pid: N/A 표시는 알려진 이슈 (앱은 정상 작동)"
echo "   - 실제 PID는 위의 'ps aux' 또는 'lsof' 명령어 결과 참고"
echo "   - 앱 작동 확인: curl http://localhost:3001/"
