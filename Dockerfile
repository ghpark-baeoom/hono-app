# ============================================================
# ARM64 vs x86_64 플랫폼 빌드 가이드
# ============================================================
#
# 1. 네이티브 빌드 (권장 - 가장 빠름):
#    docker compose build
#    → 현재 머신의 아키텍처로 빌드 (M1 Mac = ARM64, Intel Mac/EC2 = x86_64)
#
# 2. 크로스 플랫폼 빌드 (멀티 아키텍처 지원):
#    docker buildx build --platform linux/amd64,linux/arm64 -t hono-app:latest .
#    → 한 번에 여러 아키텍처용 이미지 생성 (Docker Hub 배포용)
#
# 3. 특정 플랫폼 강제 빌드:
#    docker build --platform linux/amd64 -t hono-app:latest .
#    → M1 Mac에서 x86 이미지 빌드 (느림, QEMU 에뮬레이션 사용)
#
# 4. AWS Graviton (ARM64) EC2 배포 시:
#    - ARM 네이티브 빌드가 x86 에뮬레이션보다 2-3배 빠름
#    - 같은 성능 대비 비용 20% 절감
#
# ============================================================

# Use official Bun image (latest stable version as of 2025)
# oven/bun:1.3-alpine은 멀티 아키텍처 이미지 (linux/amd64, linux/arm64 모두 지원)
FROM oven/bun:1.3-alpine AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lockb* ./
# ARM vs x86: bun install 속도는 동일하지만, 네이티브 바이너리 패키지가 있는 경우
# ARM은 자동으로 linux/arm64 바이너리를 다운로드 (예: Sharp, better-sqlite3 등)
# 크로스 컴파일이 필요한 경우 QEMU 에뮬레이션으로 느려질 수 있음
RUN bun install --frozen-lockfile --production

# Build application
FROM base AS build
COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile
COPY . .
# Build with minification and tree-shaking for optimal production bundle
# ARM vs x86: Bun의 빌드 속도는 ARM에서 더 빠를 수 있음 (Apple Silicon)
# --target=bun은 아키텍처 중립적 (런타임에 JIT 컴파일)
RUN bun build server.ts --outdir=dist --minify --target=bun

# Production image
FROM base AS production
WORKDIR /app

# Set environment to production
ENV NODE_ENV=production

# Copy only production dependencies and built application
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./

# Create non-root user for security
RUN addgroup -g 1001 -S bunuser && \
    adduser -S bunuser -u 1001
USER bunuser

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD bun fetch http://localhost:3001/health || exit 1

# Start application with built and minified JS
CMD ["bun", "run", "dist/server.js"]
