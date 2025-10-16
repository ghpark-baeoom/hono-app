# Amazon Linux 2023 (dnf) 전용 스크립트

> Amazon Linux 2023에서 사용하는 스크립트 모음 (dnf 패키지 매니저)

## 📋 개요

이 디렉토리는 **Amazon Linux 2023 (AL2023)** 환경을 위한 배포 스크립트입니다.

- Ubuntu/Debian (`apt`) → `scripts/` 디렉토리 사용
- Amazon Linux 2023 (`dnf`) → `scripts-dnf/` 디렉토리 사용 ✅

---

## 🔧 포함된 스크립트

### 1. `git-pull.sh`
Git 저장소에서 최신 코드를 pull합니다.

```bash
./scripts-dnf/git-pull.sh
```

---

### 2. `install-docker.sh`
Amazon Linux 2023에 Docker와 Docker Compose를 설치합니다.

```bash
./scripts-dnf/install-docker.sh
```

**설치 항목:**
- Docker (AL2023 공식 리포지토리)
- Docker Compose (GitHub 최신 릴리스)
- docker 그룹에 현재 사용자 추가

**설치 후:**
```bash
# SSH 재접속 후 sudo 없이 사용 가능
docker ps
docker compose version
```

---

### 3. `manual-deploy-pm2.sh`
PM2를 사용한 무중단 배포 스크립트입니다.

```bash
./scripts-dnf/manual-deploy-pm2.sh
```

**작업 순서:**
1. Git pull
2. Bun install
3. Bun build
4. PM2 reload (무중단)
5. 상태 및 로그 확인

---

### 4. `manual-deploy-docker.sh`
Docker Compose를 사용한 배포 스크립트입니다.

```bash
./scripts-dnf/manual-deploy-docker.sh
```

**작업 순서:**
1. Git pull
2. Docker 이미지 빌드
3. 컨테이너 재시작
4. 헬스 체크
5. 상태 및 로그 확인

---

## 🆚 Ubuntu vs Amazon Linux 2023 차이점

| 항목 | Ubuntu (scripts/) | Amazon Linux 2023 (scripts-dnf/) |
|------|-------------------|----------------------------------|
| **패키지 매니저** | `apt` / `apt-get` | `dnf` |
| **Docker 설치** | Docker 공식 리포지토리 추가 필요 | AL2023 공식 리포지토리에 포함 |
| **Docker Compose** | `docker-compose-plugin` (apt) | GitHub 직접 다운로드 |
| **GPG 키 관리** | `/etc/apt/keyrings/` | 불필요 (공식 리포) |
| **배포 스크립트** | 동일 | 동일 |

---

## 🚀 사용 방법

### EC2 인스턴스 유형 확인

```bash
# OS 확인
cat /etc/os-release

# Amazon Linux 2023인 경우:
# NAME="Amazon Linux"
# VERSION="2023"

# Ubuntu인 경우:
# NAME="Ubuntu"
```

### 초기 설정 (AL2023)

```bash
# 1. 프로젝트 클론
git clone https://github.com/yourusername/hono-app.git
cd hono-app

# 2. Docker 설치
./scripts-dnf/install-docker.sh

# 3. SSH 재접속 (docker 그룹 권한 적용)
exit
# SSH 다시 접속

# 4. Bun 설치
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# 5. PM2 설치 (선택사항)
npm install -g pm2

# 6. 배포
./scripts-dnf/manual-deploy-pm2.sh
# 또는
./scripts-dnf/manual-deploy-docker.sh
```

---

## ⚠️ 주의사항

### 1. Docker Compose 명령어 차이

**Ubuntu (scripts/):**
```bash
docker compose up -d  # 플러그인 방식
```

**Amazon Linux 2023 (scripts-dnf/):**
```bash
docker-compose up -d  # 독립 실행 파일
# 또는
docker compose up -d  # 심볼릭 링크 설정 시
```

두 가지 모두 작동하도록 스크립트를 작성했습니다.

---

### 2. 권한 문제

스크립트가 실행되지 않는 경우:

```bash
chmod +x scripts-dnf/*.sh
```

---

### 3. 파일 경로

배포 스크립트는 **프로젝트 루트 디렉토리**에서 실행해야 합니다.

```bash
# ✅ 올바른 실행
cd /home/ec2-user/hono-app
./scripts-dnf/manual-deploy-pm2.sh

# ❌ 잘못된 실행
cd /home/ec2-user/hono-app/scripts-dnf
./manual-deploy-pm2.sh  # git pull이 작동하지 않음
```

---

## 📚 추가 참고 자료

- [Amazon Linux 2023 공식 문서](https://docs.aws.amazon.com/linux/al2023/)
- [dnf 명령어 가이드](https://docs.fedoraproject.org/en-US/quick-docs/dnf/)
- [Docker on Amazon Linux 2023](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html)

---

## 🤝 기여

Ubuntu 스크립트 수정 시 Amazon Linux 2023 스크립트도 함께 업데이트해주세요.
