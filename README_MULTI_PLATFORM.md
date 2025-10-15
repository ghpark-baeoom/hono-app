# Docker 멀티 플랫폼 빌드 완벽 가이드

## 목차
1. [멀티 플랫폼이란?](#멀티-플랫폼이란)
2. [ARM64 vs x86_64 차이점](#arm64-vs-x86_64-차이점)
3. [빌드 방법](#빌드-방법)
4. [실전 시나리오](#실전-시나리오)
5. [트러블슈팅](#트러블슈팅)

---

## 멀티 플랫폼이란?

### 개념

멀티 플랫폼 Docker 이미지는 **하나의 이미지 태그**에 **여러 CPU 아키텍처**를 포함하는 방식입니다.

```
hono-app:latest (매니페스트 리스트)
├── linux/amd64 → Intel/AMD CPU용 이미지
└── linux/arm64 → ARM CPU용 이미지 (Apple Silicon, AWS Graviton)
```

### 작동 원리

Docker가 이미지를 pull할 때 **자동으로 현재 시스템의 아키텍처에 맞는 버전을 선택**합니다:

- **M1/M2/M3 Mac** → `linux/arm64` 버전 다운로드
- **Intel Mac/PC** → `linux/amd64` 버전 다운로드
- **AWS Graviton EC2** → `linux/arm64` 버전 다운로드
- **일반 EC2 (t3, m5 등)** → `linux/amd64` 버전 다운로드

### 장점

✅ **하나의 이미지 태그로 모든 플랫폼 지원**
- `docker pull hono-app:latest` 명령어 하나로 어디서든 동작

✅ **배포 스크립트 단순화**
- 플랫폼별 분기 처리 불필요

✅ **CI/CD 파이프라인 최적화**
- 한 번의 빌드로 모든 환경 커버

---

## ARM64 vs x86_64 차이점

### 아키텍처 비교

| 항목 | ARM64 (aarch64) | x86_64 (amd64) |
|------|-----------------|----------------|
| **CPU 예시** | Apple M1/M2/M3, AWS Graviton | Intel, AMD |
| **전력 효율** | 높음 (모바일 기반) | 보통 |
| **성능** | 최신 칩은 매우 빠름 | 전통적으로 강력 |
| **가격 (클라우드)** | 저렴 (AWS Graviton 20% 절감) | 일반 가격 |
| **Docker 빌드 속도** | M1 Mac에서 매우 빠름 | 안정적 |

### 실제 사용 환경

#### ARM64를 사용하는 경우
- 🍎 Apple Silicon Mac (M1/M2/M3/M4)
- ☁️ AWS Graviton 인스턴스 (t4g, m7g, c7g 등)
- 📱 Raspberry Pi 4 (64-bit OS)
- 🚀 Oracle Cloud ARM 인스턴스

#### x86_64를 사용하는 경우
- 💻 Intel/AMD CPU 기반 Mac, PC
- ☁️ 대부분의 EC2 인스턴스 (t3, t2, m5, c5 등)
- 🖥️ 전통적인 데이터센터 서버

---

## 빌드 방법

### 1. 네이티브 빌드 (권장 - 가장 빠름)

현재 머신의 아키텍처로만 빌드합니다.

```bash
# 일반 빌드 (현재 플랫폼만)
docker build -t hono-app:latest .

# 또는 docker compose 사용
docker compose build
```

**결과:**
- M1 Mac → ARM64 이미지 생성
- Intel Mac → x86_64 이미지 생성

**장점:**
- ⚡ 가장 빠름 (에뮬레이션 없음)
- 💯 안정적
- 🔧 로컬 개발에 최적

**단점:**
- ❌ 다른 플랫폼에서 사용 불가

---

### 2. 멀티 플랫폼 빌드 + 레지스트리 Push

Docker Hub, AWS ECR, GitHub Container Registry 등에 업로드할 때 사용합니다.

#### 사전 준비

```bash
# Docker Buildx 설정 (최초 1회)
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap
```

#### 빌드 및 Push

```bash
# Docker Hub에 푸시
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/hono-app:latest \
  --push \
  .

# AWS ECR에 푸시
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest \
  --push \
  .
```

**중요:** `--push` 플래그는 필수입니다. 멀티 플랫폼 이미지는 레지스트리로만 배포 가능합니다.

#### 사용

```bash
# 어떤 플랫폼에서든 동일한 명령어
docker pull yourusername/hono-app:latest

# M1 Mac → ARM64 버전 자동 다운로드
# Intel EC2 → x86_64 버전 자동 다운로드
```

**장점:**
- ✅ 모든 플랫폼 지원
- ✅ 프로덕션 배포 최적
- ✅ 팀 협업 용이

**단점:**
- 🐢 빌드 시간 2배 (2개 아키텍처 빌드)
- 📦 저장 공간 2배 사용
- 🌐 레지스트리 필수

---

### 3. 특정 플랫폼 강제 빌드 (크로스 컴파일)

현재 플랫폼과 다른 아키텍처용 이미지를 빌드합니다.

```bash
# M1 Mac에서 x86_64 이미지 빌드
docker buildx build \
  --platform linux/amd64 \
  -t hono-app:amd64 \
  --load \
  .

# Intel Mac에서 ARM64 이미지 빌드
docker buildx build \
  --platform linux/arm64 \
  -t hono-app:arm64 \
  --load \
  .
```

**주의:** QEMU 에뮬레이션을 사용하므로 **매우 느립니다** (2-5배).

**사용 사례:**
- Intel Mac에서 ARM EC2 배포용 이미지 테스트
- CI/CD 환경에서 특정 플랫폼 타겟팅

---

### 4. 로컬 테스트용 단일 플랫폼 빌드

```bash
# ARM64만 빌드 후 로컬 로드
docker buildx build --platform linux/arm64 -t hono-app:arm64 --load .

# x86_64만 빌드 후 로컬 로드
docker buildx build --platform linux/amd64 -t hono-app:amd64 --load .
```

**`--load`의 제약:**
- ✅ 단일 플랫폼만 로컬 로드 가능
- ❌ 멀티 플랫폼(`linux/amd64,linux/arm64`)은 `--load` 불가

---

## 실전 시나리오

### 시나리오 1: 로컬 개발 (M1 Mac)

```bash
# 네이티브 빌드 (가장 빠름)
docker compose build

# 실행
docker compose up -d

# 현재 이미지 아키텍처 확인
docker inspect hono-app:latest | grep Architecture
# → "Architecture": "arm64"
```

---

### 시나리오 2: Docker Hub 배포 (오픈소스 프로젝트)

```bash
# 1. Buildx 준비
docker buildx create --name multiplatform --use

# 2. 멀티 플랫폼 빌드 및 푸시
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/hono-app:1.0.0 \
  -t yourusername/hono-app:latest \
  --push \
  .

# 3. 매니페스트 확인
docker buildx imagetools inspect yourusername/hono-app:latest
```

**출력 예시:**
```
Name:      docker.io/yourusername/hono-app:latest
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:abc123...

Manifests:
  Name:      docker.io/yourusername/hono-app:latest@sha256:def456...
  Platform:  linux/amd64

  Name:      docker.io/yourusername/hono-app:latest@sha256:ghi789...
  Platform:  linux/arm64
```

---

### 시나리오 3: AWS ECR + EC2 배포

#### 3-1. ECR에 멀티 플랫폼 이미지 푸시

```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.ap-northeast-2.amazonaws.com

# 멀티 플랫폼 빌드 및 푸시
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest \
  --push \
  .
```

#### 3-2. EC2에서 배포 (Graviton ARM64)

```bash
# EC2 접속
ssh ubuntu@ec2-arm-instance

# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.ap-northeast-2.amazonaws.com

# Pull (자동으로 ARM64 버전 다운로드)
docker pull 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest

# 아키텍처 확인
docker inspect 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest | grep Architecture
# → "Architecture": "arm64"
```

#### 3-3. EC2에서 배포 (Intel x86_64)

```bash
# EC2 접속
ssh ubuntu@ec2-intel-instance

# 동일한 명령어
docker pull 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest

# 아키텍처 확인
docker inspect 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/hono-app:latest | grep Architecture
# → "Architecture": "amd64"
```

**핵심:** 동일한 이미지 태그로 자동으로 올바른 아키텍처를 받습니다!

---

### 시나리오 4: GitHub Actions CI/CD

`.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Multi-Platform Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            yourusername/hono-app:latest
            yourusername/hono-app:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 트러블슈팅

### 문제 1: `--load`와 멀티 플랫폼 동시 사용 불가

#### 에러 메시지
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t hono-app --load .
# ERROR: docker exporter does not currently support exporting manifest lists
```

#### 해결 방법
```bash
# 옵션 A: 레지스트리로 푸시 (권장)
docker buildx build --platform linux/amd64,linux/arm64 -t user/hono-app --push .

# 옵션 B: 단일 플랫폼만 로드
docker buildx build --platform linux/arm64 -t hono-app --load .
```

---

### 문제 2: Buildx builder가 없음

#### 에러 메시지
```bash
ERROR: multiple platforms feature is currently not supported for docker driver
```

#### 해결 방법
```bash
# Buildx builder 생성
docker buildx create --name multiplatform --use

# 확인
docker buildx inspect --bootstrap
```

---

### 문제 3: 크로스 컴파일이 너무 느림

#### 증상
M1 Mac에서 `--platform linux/amd64` 빌드 시 10분 이상 소요

#### 해결 방법
```bash
# 옵션 A: 네이티브 플랫폼만 빌드
docker build -t hono-app:latest .  # 30초

# 옵션 B: CI/CD에서 멀티 플랫폼 빌드
# GitHub Actions는 x86 러너이므로 ARM 빌드도 빠름

# 옵션 C: 각 플랫폼에서 네이티브 빌드 후 매니페스트 병합 (고급)
# (일반적으로 불필요)
```

---

### 문제 4: 네이티브 모듈 (sharp, sqlite 등) 설치 실패

#### 증상
```bash
Error: Could not load the "sharp" module using the linux-x64 runtime
```

#### 원인
M1 Mac에서 x86 이미지를 빌드했지만, 패키지가 ARM 바이너리를 설치함

#### 해결 방법
```dockerfile
# Dockerfile에서 명시적 플랫폼 지정
FROM --platform=$BUILDPLATFORM oven/bun:1.3-alpine AS base

# 빌드 인자 전달
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"
```

---

### 문제 5: 이미지 크기가 2배가 됨

#### 원인
멀티 플랫폼 이미지는 2개 아키텍처를 모두 포함하므로 레지스트리 저장 공간이 2배입니다.

#### 대응
- 각 아키텍처별 압축 후 크기는 비슷 (예: 각각 100MB)
- Pull 시에는 **하나의 아키텍처만 다운로드**되므로 사용자에게는 영향 없음
- 레지스트리 저장 공간만 2배 필요

---

## 현재 플랫폼 확인 방법

### 시스템 아키텍처 확인
```bash
# macOS/Linux
uname -m
# 출력: arm64 (M1/M2/M3) 또는 x86_64 (Intel)

# Docker 플랫폼 확인
docker info | grep Architecture
# 출력: Architecture: aarch64 (ARM) 또는 x86_64
```

### 이미지 아키텍처 확인
```bash
# 로컬 이미지
docker inspect hono-app:latest | grep Architecture

# 레지스트리 이미지 (멀티 플랫폼 매니페스트 확인)
docker buildx imagetools inspect yourusername/hono-app:latest
```

---

## 베스트 프랙티스

### ✅ DO

1. **로컬 개발은 네이티브 빌드**
   ```bash
   docker compose build  # 빠르고 안정적
   ```

2. **프로덕션 배포는 멀티 플랫폼**
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 --push
   ```

3. **CI/CD에서 멀티 플랫폼 빌드**
   - GitHub Actions, GitLab CI 등 활용

4. **베이스 이미지는 멀티 아키텍처 지원 확인**
   - `oven/bun`, `node`, `python`, `nginx` 등은 모두 지원
   - Docker Hub에서 "OS/ARCH" 탭 확인

### ❌ DON'T

1. **로컬에서 크로스 컴파일 남용**
   - 느리고 불필요한 경우가 많음

2. **멀티 플랫폼 이미지를 `--load`로 로드 시도**
   - 에러 발생, 대신 `--push` 사용

3. **플랫폼별 이미지 태그 분리**
   - `hono-app:arm64`, `hono-app:amd64` (안티패턴)
   - 대신 하나의 태그에 멀티 플랫폼 포함

---

## 참고 자료

- [Docker Buildx 공식 문서](https://docs.docker.com/buildx/working-with-buildx/)
- [Multi-platform images 가이드](https://docs.docker.com/build/building/multi-platform/)
- [AWS Graviton 가격 비교](https://aws.amazon.com/ec2/graviton/)
- [Bun Docker 이미지](https://hub.docker.com/r/oven/bun)

---

## 요약

| 상황 | 명령어 | 결과 |
|------|--------|------|
| 로컬 개발 | `docker compose build` | 현재 플랫폼 이미지 (빠름) |
| Docker Hub 배포 | `docker buildx build --platform linux/amd64,linux/arm64 --push` | 멀티 플랫폼 이미지 |
| 특정 플랫폼 테스트 | `docker buildx build --platform linux/arm64 --load` | 단일 플랫폼 로컬 이미지 |
| 매니페스트 확인 | `docker buildx imagetools inspect image:tag` | 지원 플랫폼 목록 |

**핵심:** 대부분의 경우 `docker compose build`로 충분하며, 프로덕션 배포 시에만 멀티 플랫폼 빌드를 고려하세요.
