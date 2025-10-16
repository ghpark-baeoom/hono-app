# ============================================================
# Multi-arch & Build 가이드
#   - 네이티브: docker compose build
#   - 멀티아키: docker buildx build --platform linux/amd64,linux/arm64 -t hono-app:latest .
#   - 특정 아키: docker build --platform linux/amd64 -t hono-app:latest .
# ============================================================

# 0) 공통 베이스 (Bun runtime, multi-arch)
FROM oven/bun:1.3-alpine AS base
WORKDIR /app
ENV NODE_ENV=production

# 1) deps: 프로덕션 의존성만 설치 (node_modules)
FROM base AS deps
# 패키지 메타만 먼저 복사 (캐시 극대화)
COPY package.json bun.lockb* ./
# devDependencies 제외하고 설치 (런타임용)
RUN bun install --frozen-lockfile --production \
 && rm -rf /root/.bun/install/cache 2>/dev/null || true

# 2) build: 빌드에 필요한 devDependencies 포함 설치 후 번들링
FROM base AS build
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile
# 앱 소스 복사
COPY . .
# 번들/최적화 (필요에 맞게 엔트리 조정: src/server.ts 등)
# - bun build는 tree-shaking/minify 지원
# - --target=bun: 런타임 bun 기준으로 최적화
RUN bun build server.ts --outdir=dist --minify --target=bun

# 3) production: 런타임만 포함 (가벼운 최종 이미지)
FROM base AS production
WORKDIR /app
ENV NODE_ENV=production

# (권장) 비루트 사용자 생성: UID/GID 1001 고정
RUN addgroup -g 1001 -S bunuser \
 && adduser  -u 1001 -S -G bunuser bunuser

# 프로덕션 의존성과 빌드 산출물만 복사 (처음부터 소유권 지정)
COPY --chown=bunuser:bunuser --from=deps  /app/node_modules ./node_modules
COPY --chown=bunuser:bunuser --from=build /app/dist         ./dist
COPY --chown=bunuser:bunuser --from=build /app/package.json ./package.json
# (필요 시) 정적/환경 파일 추가
# COPY --chown=bunuser:bunuser --from=build /app/public ./public

USER bunuser

# 앱 포트 (기본 3001, .env 또는 compose environment로 재정의 가능)
EXPOSE 3001

# Healthcheck: 200 OK 기대 + 에러 핸들러
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bun -e "await fetch('http://localhost:'+(process.env.PORT||'3001')+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Start (PORT는 환경변수로 주입 가능: 기본 3001)
ENV PORT=3001
CMD ["bun", "run", "dist/server.js"]
