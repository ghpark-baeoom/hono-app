module.exports = {
  apps: [
    {
      name: "hono-app", // PM2 프로세스 이름
      script: "dist/server.js", // 실행할 메인 파일 경로
      interpreter: "bun", // Bun 런타임 사용
      instances: 2, // 실행할 인스턴스 개수 (무중단 배포를 위해 최소 2개 이상)
      exec_mode: "cluster", // 실행 모드 (cluster: 여러 인스턴스, fork: 단일 인스턴스)
      autorestart: true, // 프로세스 종료 시 자동 재시작
      watch: false, // 파일 변경 감지 후 자동 재시작 (개발: true, 프로덕션: false)
      max_memory_restart: "1G", // 메모리 사용량이 1GB 초과 시 자동 재시작
      // Bun은 .env 파일을 자동으로 로드하므로 별도 설정 불필요
      env: {
        NODE_ENV: "production", // 환경 변수 설정
        // PORT: 3000 // 필요 시 포트 설정
      },
      kill_timeout: 5000, // 프로세스 종료 대기 시간 (밀리초)
      wait_ready: true, // 앱이 준비될 때까지 대기 (listen 완료 확인)
      listen_timeout: 10000, // listen 완료 대기 최대 시간 (밀리초)
    },
  ],
};
