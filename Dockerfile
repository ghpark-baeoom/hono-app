# ============================================================
# 🎯 극도로 최적화된 Bun Docker 빌드 (최소 이미지 크기)
# ============================================================
# Multi-arch & Build 가이드
#   - 네이티브: docker compose build
#   - 멀티아키: docker buildx build --platform linux/amd64,linux/arm64 -t hono-app:latest .
#   - 특정 아키: docker build --platform linux/amd64 -t hono-app:latest .
#   - 크기 확인: docker images | grep hono-app
# ============================================================

# 🔴 STAGE 1: Builder (의존성 + 빌드)
FROM oven/bun:1.3-alpine AS builder

WORKDIR /app

# 1.1) 빠른 캐시를 위해 패키지 파일 먼저 복사
COPY package.json bun.lockb* ./

# 1.2) 모든 의존성 설치 (devDependencies 포함)
RUN bun install --frozen-lockfile && \
    rm -rf /root/.bun/install/cache 2>/dev/null || true

# 1.3) 소스 코드 복사
COPY . .

# 1.4) 번들링 (tree-shaking + minify)
# 결과: dist/server.js (모든 의존성 포함, 최적화됨)
RUN bun build server.ts \
    --outdir=dist \
    --minify \
    --target=bun \
    --external:@hono/hono \
    --splitting

# 1.5) 불필요한 파일 정리 (소스, 캐시 제거)
RUN rm -rf \
    node_modules \
    .git \
    .gitignore \
    src \
    .env* \
    *.md \
    .DS_Store

# 🟢 STAGE 2: 런타임 (최소 이미지)
FROM oven/bun:1.3-alpine AS production

WORKDIR /app

# 2.1) 비루트 사용자 생성 (보안)
RUN addgroup -g 1001 -S bunuser && \
    adduser -u 1001 -S -G bunuser bunuser

# 2.2) Builder에서 필요한 파일만 복사
# - package.json: 버전 정보용 (선택사항)
# - dist/: 빌드된 번들 파일
COPY --chown=bunuser:bunuser --from=builder /app/package.json ./
COPY --chown=bunuser:bunuser --from=builder /app/dist ./dist

# 2.3) 비루트 사용자로 전환
USER bunuser

# 2.4) 앱 포트 (4000: Nginx, 4001/4002: Blue/Green 내부용)
EXPOSE 4000

# 2.5) 헬스 체크 (성능 최적화: 간단한 fetch)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bun -e "await fetch('http://localhost:'+(process.env.PORT||'4000')+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# 2.6) 환경 변수 설정
ENV NODE_ENV=production PORT=4000

# 2.7) 앱 실행
CMD ["bun", "run", "dist/server.js"]

# ============================================================
# 📊 최적화 기법 설명
# ============================================================
# 1. Multi-stage build (2단계)
#    - Builder: 모든 의존성 + 소스코드 → 최종 번들 생성
#    - Production: 번들 파일만 → 가벼운 최종 이미지
#
# 2. Bun 번들링 최적화
#    - --minify: 코드 축소 (공백, 주석 제거)
#    - --target=bun: Bun 런타임 기준 최적화
#    - --splitting: 번들 분할 (공통 코드 추출)
#
# 3. 레이어 정리
#    - Builder에서 node_modules, 소스 삭제 (불필요)
#    - Production에 번들 파일만 복사 (최소)
#
# 4. Alpine 기본 이미지
#    - oven/bun:1.3-alpine ≈ 140MB (최소)
#    - Node.js alpine (181MB) vs 매우 효율적
#
# 5. 캐시 최적화
#    - package.json 먼저 복사 → 의존성 캐시
#    - 소스 코드 나중에 복사 → 자주 변경되지 않음
#    - 빌드 성능 향상 (개발 사이클 빨라짐)
#
# ============================================================
# 📈 예상 이미지 크기
# ============================================================
# 최적화 전: ~500-600MB
#   - Base: 140MB
#   - node_modules: 200-300MB
#   - 소스코드: 50MB
#   - 빌드 파일: 50MB
#
# 최적화 후: ~160-200MB
#   - Base: 140MB
#   - 번들 파일: 20MB
#   - 메타데이터: <5MB
#
# 감소율: ~65-70% 🚀
# ============================================================
# 🔧 빌드 명령어
# ============================================================
# docker build -t hono-app:latest .
# docker buildx build --platform linux/amd64,linux/arm64 -t hono-app:latest .
#
# 크기 비교:
# docker images hono-app
# docker inspect hono-app:latest --format='{{.Size}}'
# ============================================================
