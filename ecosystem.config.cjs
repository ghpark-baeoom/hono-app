module.exports = {
  apps: [
    {
      name: 'hono-app', // PM2 프로세스 이름
      script: 'dist/server.js', // 실행할 메인 파일 경로
      interpreter: 'bun', // Bun 런타임 사용
      interpreter_args: '', // 인터프리터 추가 인자 (빈 문자열로 명시)
      instances: 2, // Linux에서 reusePort로 포트 공유 (무중단 배포 및 부하 분산)
      exec_mode: 'fork', // Bun은 PM2 cluster 모드 미지원 (fork만 가능)
      autorestart: true, // 프로세스 종료 시 자동 재시작
      watch: false, // 파일 변경 감지 후 자동 재시작 (개발: true, 프로덕션: false)
      max_memory_restart: '1G', // 메모리 사용량이 1GB 초과 시 자동 재시작
      // Bun은 .env 파일을 자동으로 로드하므로 별도 설정 불필요
      env: {
        NODE_ENV: 'production', // 환경 변수 설정
        // PORT: 3000 // 필요 시 포트 설정
      },
      kill_timeout: 5000, // 프로세스 종료 대기 시간 (밀리초)
      wait_ready: true, // 앱이 준비될 때까지 대기 (listen 완료 확인)
      listen_timeout: 10000, // listen 완료 대기 최대 시간 (밀리초)
      // PID 추적 문제 해결을 위한 추가 설정
      merge_logs: true, // 여러 인스턴스의 로그 병합
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z', // 로그 날짜 포맷
      error_file: '/home/ec2-user/.pm2/logs/hono-app-error.log', // 에러 로그 통합
      out_file: '/home/ec2-user/.pm2/logs/hono-app-out.log', // 출력 로그 통합
      combine_logs: true, // 로그 결합
      time: true, // 로그에 타임스탬프 추가
    },
  ],
}
