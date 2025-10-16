#!/bin/bash

# Amazon Linux 2023용 Docker 설치 스크립트 (dnf)

# 1) 시스템 업데이트
sudo dnf update -y

# 2) Docker 설치 (Amazon Linux 2023는 공식 리포지토리에 docker 포함)
sudo dnf install -y docker

# 3) Docker 서비스 시작 및 자동 시작 설정
sudo systemctl start docker
sudo systemctl enable docker

# 4) (옵션) sudo 없이 사용하기 위해 현재 사용자를 docker 그룹에 추가
if id -nG "$USER" | grep -qvw docker; then
  sudo usermod -aG docker "$USER"
  echo "[INFO] docker 그룹에 현재 사용자 추가됨. 새 SSH 접속 후 반영됩니다."
fi

# 5) Docker Compose 설치 (AL2023는 별도 설치 필요)
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 6) 버전 출력 (테스트)
echo ""
echo "✅ Docker 설치 완료!"
docker --version
docker-compose --version || docker compose version

echo ""
echo "⚠️  docker 그룹 권한을 적용하려면 SSH 재접속이 필요합니다."
echo "   재접속 후: docker ps (sudo 없이 실행 가능)"
