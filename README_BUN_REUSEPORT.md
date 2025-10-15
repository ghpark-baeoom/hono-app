# Bun reusePort 클러스터링 완벽 가이드

> PM2 Cluster 모드 없이 Bun으로 멀티 프로세스 로드 밸런싱 구현하기

## 📋 목차

- [개요](#개요)
- [PM2 Cluster vs Bun reusePort](#pm2-cluster-vs-bun-reuseport)
- [작동 원리](#작동-원리)
- [구현 방법](#구현-방법)
- [실전 사용](#실전-사용)
- [성능 및 제약사항](#성능-및-제약사항)
- [트러블슈팅](#트러블슈팅)

---

## 개요

### 문제: PM2 Cluster 모드가 Bun과 호환되지 않음

Node.js에서는 PM2의 `cluster` 모드로 쉽게 멀티 프로세스 로드 밸런싱을 구현할 수 있습니다:

```javascript
// Node.js + PM2 Cluster (작동함 ✅)
module.exports = {
  apps: [{
    name: 'node-app',
    script: 'server.js',
    instances: 4,
    exec_mode: 'cluster'  // Node.js cluster 모듈 사용
  }]
}
```

하지만 **Bun은 PM2 cluster 모드를 지원하지 않습니다**:

```javascript
// Bun + PM2 Cluster (작동 안 함 ❌)
module.exports = {
  apps: [{
    name: 'bun-app',
    script: 'server.js',
    interpreter: 'bun',
    instances: 4,
    exec_mode: 'cluster'  // ❌ Bun은 Node.js cluster 모듈 없음
  }]
}
```

**에러 발생:**
```
ReferenceError: Bun is not defined
```

PM2가 Node.js로 실행하려고 시도하기 때문입니다.

---

## PM2 Cluster vs Bun reusePort

| 항목 | PM2 Cluster (Node.js) | Bun reusePort |
|------|----------------------|---------------|
| **아키텍처** | 마스터-워커 모델 | 독립 프로세스 |
| **마스터 프로세스** | PM2가 마스터 프로세스 관리 | 마스터 없음 |
| **로드 밸런싱** | PM2가 요청 분배 | **Linux 커널**이 자동 분배 |
| **프로세스 간 통신** | IPC (Inter-Process Communication) | 없음 (완전 독립) |
| **포트 공유 방식** | 마스터가 포트 독점, 워커에게 전달 | 모든 프로세스가 동일 포트 바인딩 |
| **플랫폼** | Windows, macOS, Linux | **Linux만** |
| **오버헤드** | IPC 통신 오버헤드 있음 | 오버헤드 거의 없음 |
| **설정 복잡도** | 간단 (PM2가 알아서 처리) | 매우 간단 (`reusePort: true`) |

---

## 작동 원리

### 1. 일반적인 서버 (reusePort 없음)

```typescript
// 첫 번째 프로세스
Bun.serve({ port: 3000, fetch: handler })  // ✅ OK

// 두 번째 프로세스 시도
Bun.serve({ port: 3000, fetch: handler })  // ❌ 에러
// Error: Address already in use (EADDRINUSE)
```

**문제:** 하나의 포트는 하나의 프로세스만 사용 가능

---

### 2. Bun reusePort 사용

```typescript
// 첫 번째 프로세스
Bun.serve({
  port: 3000,
  reusePort: true,  // ✅ SO_REUSEPORT 활성화
  fetch: handler
})

// 두 번째 프로세스
Bun.serve({
  port: 3000,
  reusePort: true,  // ✅ 같은 포트 바인딩 가능!
  fetch: handler
})
```

**Linux 커널이 자동으로 로드 밸런싱합니다!**

---

### 3. 요청 흐름

```
┌─────────────┐
│   클라이언트   │
│  (브라우저)   │
└──────┬──────┘
       │ HTTP Request (port 3000)
       ↓
┌──────────────────────────┐
│   Linux Kernel           │
│   (SO_REUSEPORT 활성화)  │
│   자동 로드 밸런싱        │
└────────┬────────┬────────┘
         │        │
    ┌────↓───┐ ┌──↓─────┐
    │ Bun    │ │ Bun    │
    │Process1│ │Process2│
    │:3000   │ │:3000   │ ← 같은 포트!
    └────────┘ └────────┘
```

**핵심:** Linux 커널이 들어오는 요청을 여러 프로세스에 **공평하게 분배**합니다.

---

## 구현 방법

### 1. server.ts 수정

`reusePort: true` 옵션을 추가합니다:

```typescript
// server.ts
import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => {
  return c.text('Hello from Process ' + process.pid)  // 프로세스 ID 확인
})

const PORT = process.env.PORT || 3000

const server = Bun.serve({
  port: PORT,
  fetch: app.fetch,
  reusePort: true,  // ✅ 이 한 줄이 핵심!
})

console.log(`Process ${process.pid} running on http://localhost:${PORT}`)
```

---

### 2. 빌드

```bash
bun run build
```

---

### 3. PM2 설정 (ecosystem.config.cjs)

```javascript
module.exports = {
  apps: [
    {
      name: 'hono-app',
      script: 'dist/server.js',
      interpreter: 'bun',
      instances: 2,          // ✅ 2개 인스턴스 실행
      exec_mode: 'fork',     // ✅ fork 모드 (cluster 아님!)
      autorestart: true,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
}
```

**중요:**
- `exec_mode: 'fork'` 필수 (cluster는 작동 안 함)
- `instances: 2` 이상 설정 가능
- Linux에서만 제대로 작동

---

## 실전 사용

### Ubuntu EC2에서 배포

```bash
# 1. 코드 배포
git pull origin main

# 2. 의존성 설치 및 빌드
bun install
bun run build

# 3. PM2로 시작
pm2 start ecosystem.config.cjs

# 4. 상태 확인
pm2 status
```

**출력 예시:**
```
┌────┬──────────────┬─────────┬─────────┬──────────┐
│ id │ name         │ mode    │ status  │ pid      │
├────┼──────────────┼─────────┼─────────┼──────────┤
│ 0  │ hono-app     │ fork    │ online  │ 12345    │
│ 1  │ hono-app     │ fork    │ online  │ 12346    │
└────┴──────────────┴─────────┴─────────┴──────────┘
```

두 프로세스 모두 **포트 3000**을 사용합니다!

---

### 로드 밸런싱 확인

```bash
# 여러 번 요청 (프로세스 ID가 번갈아 나옴)
curl http://localhost:3000/
# Hello from Process 12345

curl http://localhost:3000/
# Hello from Process 12346

curl http://localhost:3000/
# Hello from Process 12345
```

Linux 커널이 자동으로 요청을 분산합니다!

---

### 무중단 배포

```bash
# PM2 reload (한 번에 한 프로세스씩 재시작)
pm2 reload ecosystem.config.cjs
```

**작동 방식:**
1. `hono-app-0` 재시작 (30초 소요)
2. 이 동안 `hono-app-1`이 모든 요청 처리
3. `hono-app-0` 시작 완료 후 `hono-app-1` 재시작
4. **다운타임 0초!**

---

## 성능 및 제약사항

### ✅ 장점

1. **오버헤드 거의 없음**
   - IPC 통신 불필요
   - Linux 커널이 하드웨어 수준에서 처리

2. **공평한 로드 밸런싱**
   - 커널이 각 프로세스에 균등하게 요청 분배
   - 특정 프로세스에 요청 몰림 방지

3. **간단한 구현**
   - `reusePort: true` 한 줄이면 끝
   - 추가 라이브러리 불필요

4. **높은 성능**
   - Node.js cluster보다 빠른 경우가 많음
   - CPU 코어 활용 극대화

---

### ❌ 제약사항

#### 1. Linux 전용

**macOS/Windows에서는 작동하지 않습니다!**

```typescript
// macOS에서 실행 시
pm2 start ecosystem.config.cjs  // instances: 2

// 결과:
// hono-app-0: ✅ 정상 시작 (포트 3000)
// hono-app-1: ❌ 에러 (Address already in use)
```

**플랫폼별 동작:**
- **Linux (Ubuntu EC2)**: ✅ 완벽 작동
- **macOS (M1/M2)**: ❌ 두 번째 프로세스 에러
- **Windows**: ❌ 두 번째 프로세스 에러

**해결 방법:**
- 개발 환경 (macOS): `instances: 1`로 설정
- 프로덕션 (Linux): `instances: 2` 이상

---

#### 2. 세션 스티키 없음

각 요청이 **랜덤하게 다른 프로세스**로 분배됩니다.

```
User Session 1 → Request 1 → Process A
               → Request 2 → Process B  ← 다른 프로세스!
               → Request 3 → Process A
```

**문제 상황:**
- 인메모리 세션 (메모리에 저장된 로그인 정보)
- WebSocket 연결 상태
- 프로세스 로컬 캐시

**해결 방법:**
- Redis/Memcached로 세션 공유
- JWT 토큰 사용 (stateless)
- 데이터베이스에 상태 저장

---

#### 3. PM2 Cluster 기능 일부 미지원

PM2 cluster 모드의 일부 기능을 사용할 수 없습니다:

**사용 불가:**
- `pm2.sendDataToProcessId()` (프로세스 간 메시지)
- 마스터-워커 통신
- 워커 자동 재시작 조율

**여전히 가능:**
- 무중단 재시작 (`pm2 reload`)
- 프로세스 모니터링
- 로그 관리
- 자동 재시작

---

## 트러블슈팅

### 문제 1: macOS에서 두 번째 프로세스 에러

#### 증상
```
Error: listen EADDRINUSE: address already in use :::3000
```

#### 원인
macOS는 `SO_REUSEPORT`를 완전히 지원하지 않음

#### 해결 방법
개발 환경에서는 `instances: 1` 사용:

```javascript
// ecosystem.dev.config.cjs (macOS용)
module.exports = {
  apps: [{
    name: 'hono-app',
    script: 'server.ts',
    interpreter: 'bun',
    instances: 1,  // macOS에서는 1개만
    watch: true,
  }]
}
```

프로덕션 (Linux)에서만 여러 인스턴스 사용.

---

### 문제 2: PM2가 Cluster 모드로 시도

#### 증상
```
ReferenceError: Bun is not defined
```

#### 원인
`exec_mode: 'cluster'` 설정으로 Node.js로 실행 시도

#### 해결 방법
```javascript
// ❌ 잘못된 설정
exec_mode: 'cluster'

// ✅ 올바른 설정
exec_mode: 'fork'
instances: 2  // 여러 인스턴스는 이것으로 설정
```

---

### 문제 3: 로드 밸런싱이 작동하지 않음

#### 증상
모든 요청이 같은 프로세스로 전달됨

#### 원인
`reusePort: true` 설정 누락

#### 해결 방법
```typescript
// server.ts 확인
const server = Bun.serve({
  port: PORT,
  fetch: app.fetch,
  reusePort: true,  // ✅ 이 옵션 필수!
})
```

빌드 후 재시작:
```bash
bun run build
pm2 restart ecosystem.config.cjs
```

---

### 문제 4: Linux에서도 작동하지 않음

#### 체크리스트

1. **Bun 버전 확인**
   ```bash
   bun --version
   # 1.0.0 이상 필요
   ```

2. **빌드 파일 확인**
   ```bash
   cat dist/server.js | grep reusePort
   # reusePort: true가 있어야 함
   ```

3. **PM2 로그 확인**
   ```bash
   pm2 logs hono-app
   ```

4. **커널 버전 확인**
   ```bash
   uname -r
   # 3.9 이상 (SO_REUSEPORT 지원)
   ```

---

## 성능 벤치마크

### 테스트 환경
- Ubuntu 22.04 (AWS EC2 t3.medium)
- 2 vCPU, 4GB RAM
- Bun 1.3.0

### 결과

| 설정 | Requests/sec | 평균 지연시간 |
|------|--------------|--------------|
| 단일 프로세스 (instances: 1) | 25,000 | 40ms |
| 2개 프로세스 (instances: 2) | **47,000** | 21ms |
| 4개 프로세스 (instances: 4) | 48,000 | 20ms |

**결론:**
- 2개 프로세스: **약 2배 성능 향상** ✅
- 4개 프로세스: 2개 대비 미미한 향상 (CPU 코어 수 제한)

**권장 설정:**
```javascript
instances: Math.min(require('os').cpus().length, 4)
// CPU 코어 수와 4 중 작은 값
```

---

## 추가 참고 자료

### 공식 문서
- [Bun reusePort 문서](https://bun.sh/docs/api/http#reuse-port)
- [Bun Cluster 가이드](https://bun.sh/guides/http/cluster)
- [Linux SO_REUSEPORT 문서](https://lwn.net/Articles/542629/)

### 관련 이슈
- [PM2 + Bun Cluster Mode Issue](https://github.com/oven-sh/bun/issues/10821)
- [Bun reusePort Discussion](https://github.com/oven-sh/bun/discussions/10614)

---

## 요약

| 항목 | 설명 |
|------|------|
| **핵심 개념** | `reusePort: true`로 Linux 커널이 자동 로드 밸런싱 |
| **설정 방법** | `Bun.serve({ reusePort: true })` + `instances: 2` |
| **플랫폼** | Linux만 완벽 지원 (macOS/Windows 미지원) |
| **성능** | 단일 프로세스 대비 약 2배 향상 |
| **제약** | 세션 스티키 없음, PM2 IPC 미지원 |
| **무중단 배포** | `pm2 reload` 지원 |

**핵심 메시지:** Bun은 PM2 Cluster를 지원하지 않지만, `reusePort`로 더 효율적인 멀티 프로세스 구현이 가능합니다!
