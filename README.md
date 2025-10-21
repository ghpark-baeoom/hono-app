# Hono + Bun 백엔드 애플리케이션

> 경량 웹 프레임워크 Hono와 초고속 JavaScript 런타임 Bun을 활용한 프로덕션 레디 백엔드 서버

## 📋 목차

- [기술 스택](#기술-스택)
- [프로젝트 구조](#프로젝트-구조)
- [시작하기](#시작하기)
- [개발](#개발)
- [배포](#배포)
- [API 엔드포인트](#api-엔드포인트)
- [미들웨어](#미들웨어)
- [참고 문서](#참고-문서)

---

## 🛠️ 기술 스택

| 구분              | 기술                     | 버전 | 설명                                  |
| ----------------- | ------------------------ | ---- | ------------------------------------- |
| **런타임**        | [Bun](https://bun.sh)    | 1.3+ | 빠른 JavaScript 런타임 (Node.js 대체) |
| **프레임워크**    | [Hono](https://hono.dev) | 4.9+ | 경량 웹 프레임워크 (Express 대체)     |
| **언어**          | TypeScript               | 5.0+ | 타입 안전성                           |
| **린터/포매터**   | Biome                    | 2.2+ | ESLint + Prettier 통합 (Rust 기반)    |
| **컨테이너**      | Docker                   | -    | 멀티 플랫폼 지원 (ARM64/x86_64)       |
| **프로세스 관리** | PM2                      | -    | 무중단 배포 및 클러스터링             |

### 왜 Bun + Hono인가?

**성능:**

- Node.js + Express 대비 **2-3배 빠른 HTTP 처리**
- **30-50% 적은 메모리 사용량**
- TypeScript 네이티브 지원 (별도 컴파일 불필요)

**개발 경험:**

- `bun install`이 npm보다 **10-20배 빠름**
- `.env` 파일 자동 로드 (dotenv 불필요)
- Hot Module Replacement (HMR) 기본 지원

**비용 절감:**

- EC2 인스턴스 사이즈 다운그레이드 가능
- AWS Graviton (ARM64)과 완벽 호환

---

## 📁 프로젝트 구조

```
hono-app/
├── server.ts                    # 메인 애플리케이션 진입점
├── package.json                 # 의존성 및 스크립트
├── bun.lockb                    # Bun 잠금 파일
├── tsconfig.json                # TypeScript 설정
├── biome.json                   # Biome 린터/포매터 설정
├── .biomeignore                 # Biome 제외 파일
│
├── Dockerfile                   # 멀티 플랫폼 Docker 이미지 (ARM64/x86_64)
├── docker-compose.yml           # Docker Compose 설정
├── .dockerignore                # Docker 빌드 제외 파일
│
├── ecosystem.config.cjs         # PM2 프로세스 관리 설정 (Bun + reusePort)
│
├── scripts/                     # Ubuntu/Debian 배포 스크립트 (apt)
│   ├── install-docker.sh        # Docker 설치 스크립트
│   ├── manual-deploy-pm2.sh     # PM2 배포
│   ├── manual-deploy-docker.sh  # Docker Compose 배포
│   └── git-pull.sh              # Git pull 헬퍼
│
├── scripts-dnf/                 # Amazon Linux 2023 배포 스크립트 (dnf)
│   ├── README.md                # AL2023 가이드
│   ├── install-docker.sh        # Docker 설치 (dnf)
│   ├── manual-deploy-pm2.sh     # PM2 배포
│   ├── manual-deploy-docker.sh  # Docker Compose 배포
│   └── git-pull.sh              # Git pull 헬퍼
│
├── dist/                        # 빌드 출력 (생성됨)
│   └── server.js
│
├── README.md                    # 메인 문서 (본 파일)
├── README_MULTI_PLATFORM.md     # Docker 멀티 플랫폼 가이드
└── README_BUN_REUSEPORT.md      # Bun reusePort 클러스터링 가이드
```

---

## 🚀 시작하기

### 사전 요구사항

- **Bun 1.3+** 설치 ([설치 가이드](https://bun.sh/docs/installation))
  ```bash
  curl -fsSL https://bun.sh/install | bash
  ```

### 설치

```bash
# 의존성 설치
bun install

# 개발 서버 실행 (Hot Reload)
bun run dev
```

서버가 `http://localhost:4000`에서 실행됩니다.

---

## 💻 개발

### 사용 가능한 스크립트

| 명령어             | 설명                                 |
| ------------------ | ------------------------------------ |
| `bun run dev`      | 개발 서버 시작 (Hot Reload)          |
| `bun run build`    | 프로덕션 빌드 (minify, tree-shaking) |
| `bun run start`    | 빌드된 파일 실행                     |
| `bun run lint`     | 코드 린트 체크                       |
| `bun run lint:fix` | 린트 자동 수정                       |
| `bun run format`   | 코드 포매팅                          |
| `bun run check`    | 린트 + 포맷 한 번에 실행             |

### 환경 변수

`.env` 파일을 생성하여 환경 변수를 설정하세요:

```bash
PORT=4000
NODE_ENV=development
```

Bun은 `.env` 파일을 자동으로 로드합니다 (dotenv 패키지 불필요).

### 코드 품질

이 프로젝트는 [Biome](https://biomejs.dev)를 사용합니다:

```bash
# 저장 전 자동 체크
bun run check
```

**Biome 특징:**

- ESLint + Prettier를 하나로 통합
- Rust 기반으로 **35배 빠름**
- 자동 import 정리

---

## 🐳 Docker로 실행

### 로컬 실행

```bash
# 빌드 및 실행
docker compose up -d

# 로그 확인
docker compose logs -f

# 중지
docker compose down
```

### 이미지 크기

현재 프로덕션 이미지: **약 134MB** (Alpine Linux 기반)

### 멀티 플랫폼 지원

이 프로젝트는 **ARM64 (Apple Silicon, AWS Graviton)**와 **x86_64 (Intel/AMD)** 모두 지원합니다.

자세한 내용은 [README_MULTI_PLATFORM.md](./README_MULTI_PLATFORM.md)를 참고하세요.

---

## 🚢 배포

### 방법 1: PM2로 배포 (권장)

**장점:** 무중단 배포, 클러스터링, 자동 재시작

```bash
# EC2에 접속 후
cd /home/ubuntu/hono-app

# 배포 스크립트 실행
./scripts/manual-deploy-pm2.sh
```

**스크립트 내용:**

1. Git pull
2. `bun install`
3. `bun run build`
4. `pm2 reload` (무중단 재시작)

**PM2 명령어:**

```bash
# 시작
pm2 start ecosystem.config.cjs

# 상태 확인
pm2 status

# 로그 확인
pm2 logs

# 재시작
pm2 reload ecosystem.config.cjs

# 중지
pm2 stop hono-app
```

### 방법 2: Docker Compose로 배포

```bash
# EC2에 접속 후
cd /home/ubuntu/hono-app

# 배포 스크립트 실행
./scripts/manual-deploy-docker.sh
```

**스크립트 내용:**

1. Git pull
2. Docker 이미지 리빌드
3. 컨테이너 재시작 (무중단)

### 방법 3: 직접 실행

```bash
# 프로덕션 빌드
bun run build

# 실행
bun run start
```

---

## 📡 API 엔드포인트

### `GET /`

기본 헬스 체크

**응답:**

```
💗 HELLO WORLD
```

---

### `GET /health`

상세 헬스 체크 (모니터링용)

**응답:**

```
✅ HELATH CHECK SUCCESS
```

**상태 코드:** `200`

---

### `GET /api/users/:id`

사용자 정보 조회 (예제)

**파라미터:**

- `id` (string): 사용자 ID

**응답 예시:**

```json
{
  "id": "123",
  "name": "User 123"
}
```

---

### `POST /api/posts`

게시물 생성 (예제)

**요청 본문:**

```json
{
  "title": "New Post",
  "content": "Post content"
}
```

**응답:**

```json
{
  "message": "Post created",
  "data": {
    "title": "New Post",
    "content": "Post content"
  }
}
```

**상태 코드:** `201`

---

## 🔧 미들웨어

### 1. Trailing Slash 제거

`/api/users/` → `/api/users` (301 리다이렉트)

루트 경로(`/`)는 예외 처리됩니다.

**구현 위치:** `server.ts:6-16`

---

### 2. 요청 로깅

모든 HTTP 요청을 콘솔에 로깅합니다.

**로그 형식:**

```
[2025-01-15T10:30:45.123Z] 192.168.1.1 - GET /api/users/123 200 - 15ms
```

**기능:**

- 클라이언트 IP 추출 (`X-Forwarded-For`, `X-Real-IP` 지원)
- IPv6 → IPv4 변환
- 요청 처리 시간 측정

**구현 위치:** `server.ts:18-46`

---

### 3. 에러 핸들링

#### Uncaught Exception

예상치 못한 동기 에러 처리

```javascript
process.on("uncaughtException", (error) => {
  console.error("Uncaught Exception:", error);
  process.exit(1);
});
```

#### Unhandled Rejection

Promise rejection 미처리 에러

```javascript
process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});
```

**구현 위치:** `server.ts:66-75`

---

### 4. Graceful Shutdown

`SIGINT`, `SIGTERM` 시그널 수신 시 안전하게 종료

**동작:**

1. 새 요청 수신 중단
2. 진행 중인 요청 완료 대기
3. 10초 타임아웃 (강제 종료)
4. 서버 종료

**PM2와의 호환성:**

- `pm2 reload` 명령 시 무중단 재시작 가능
- `ecosystem.config.cjs`의 `wait_ready`, `kill_timeout` 설정과 연동

**구현 위치:** `server.ts:91-114`

---

## 🔒 보안 고려사항

### 현재 구현

- ✅ Non-root 유저로 Docker 컨테이너 실행
- ✅ 프로덕션 의존성만 포함 (devDependencies 제외)
- ✅ 최소 권한 원칙 (Alpine Linux)

### 추가 권장사항

- [ ] CORS 설정 추가 (프로덕션)
- [ ] Rate Limiting 미들웨어
- [ ] Helmet 헤더 보안
- [ ] 환경 변수 검증 (zod 등)

---

## 📊 성능 최적화

### 빌드 최적화

```bash
bun build server.ts --outdir=dist --minify --target=bun
```

**최적화 기법:**

- Tree-shaking (사용하지 않는 코드 제거)
- Minification (코드 압축)
- `--target=bun` (Bun 런타임 최적화)

### 클러스터링 (Bun reusePort)

Bun은 PM2 cluster 모드를 지원하지 않지만, `reusePort: true`로 멀티 프로세스 로드 밸런싱이 가능합니다 (Linux만).

**설정:** `ecosystem.config.cjs`

```javascript
instances: 2,        // 인스턴스 개수 (Linux에서 reusePort와 함께 사용)
exec_mode: "fork",   // Bun은 fork 모드만 지원
```

**server.ts:**

```typescript
Bun.serve({
  reusePort: true, // Linux 커널이 자동 로드 밸런싱
});
```

자세한 내용은 [README_BUN_REUSEPORT.md](./README_BUN_REUSEPORT.md)를 참고하세요.

---

## 🧪 테스트

```bash
# 헬스 체크
curl http://localhost:4000/health

# API 테스트
curl http://localhost:4000/api/users/123

# POST 요청 테스트
curl -X POST http://localhost:4000/api/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Hello"}'
```

---

## 📚 참고 문서

### 공식 문서

- [Bun 공식 문서](https://bun.sh/docs)
- [Hono 공식 문서](https://hono.dev)
- [Biome 공식 문서](https://biomejs.dev)

### 프로젝트 문서

- [멀티 플랫폼 Docker 가이드](./README_MULTI_PLATFORM.md)
- [Bun reusePort 클러스터링 가이드](./README_BUN_REUSEPORT.md)
- [Amazon Linux 2023 배포 가이드](./scripts-dnf/README.md)
- [PM2 설정](./ecosystem.config.cjs)

### 관련 리소스

- [Bun vs Node.js 벤치마크](https://bun.sh/docs/benchmarks)
- [Hono 성능 비교](https://hono.dev/concepts/benchmarks)
- [Docker Buildx 멀티 플랫폼](https://docs.docker.com/build/building/multi-platform/)

---

## 🤝 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 라이선스

This project is licensed under the MIT License.

---

## 🙋 FAQ

### Q: Bun은 프로덕션에서 안정적인가요?

A: 2024년 9월 Bun 1.0이 출시되었으며, 현재 1.3 버전은 프로덕션 사용에 충분히 안정적입니다. Vercel, Railway 등의 플랫폼에서 공식 지원합니다.

### Q: Node.js 패키지와 호환되나요?

A: 대부분의 npm 패키지가 호환됩니다. 다만 네이티브 C++ 애드온을 사용하는 일부 패키지는 제한될 수 있습니다.

### Q: PM2와 Docker 중 무엇을 선택해야 하나요?

A:

- **PM2**: 간단한 배포, 로그 관리가 쉬움, 낮은 오버헤드
- **Docker**: 환경 격리, 확장성, Kubernetes 등과 통합 용이

소규모 프로젝트는 PM2, 마이크로서비스 아키텍처는 Docker를 권장합니다.

### Q: AWS Graviton (ARM64)에서 사용할 수 있나요?

A: 네! 이 프로젝트는 ARM64를 완벽 지원하며, Graviton 인스턴스에서 x86 대비 20% 비용 절감이 가능합니다.

### Q: Ubuntu와 Amazon Linux 2023 중 어떤 것을 사용해야 하나요?

A:

- **Ubuntu (scripts/)**: 범용적으로 사용, 커뮤니티 지원 풍부
- **Amazon Linux 2023 (scripts-dnf/)**: AWS 최적화, AL2023 전용

둘 다 완벽히 지원되므로 선호도에 따라 선택하세요.

### Q: Bun의 reusePort는 어떤 OS에서 작동하나요?

A: **Linux만 작동**합니다. macOS와 Windows에서는 무시되며, `instances: 1`로 설정해야 합니다. 자세한 내용은 [README_BUN_REUSEPORT.md](./README_BUN_REUSEPORT.md)를 참고하세요.
