import type { Context, Next } from "hono";
import { Hono } from "hono";
import { getClientIp } from "./lib/ip";

const app = new Hono();

/**
 * ✅ URL 끝의 슬래시("/")를 제거하는 Hono 미들웨어 (루트 "/"는 예외)
 *
 * @description
 * - 표준 URL API를 사용하여 URL 전체를 안전하게 파싱합니다.
 * - 쿼리스트링(`?a=1&b=2`)은 그대로 유지합니다.
 * - 인코딩된 문자(`%20`, `%2F` 등)나 다중 슬래시(`///`)도 정상적으로 처리합니다.
 * - Nginx 등 리버스 프록시 뒤에서도 원본 요청 경로를 기준으로 작동합니다.
 * - URL 파싱 오류 발생 시, 다음 미들웨어로 안전하게 제어를 넘깁니다.
 *
 * @example
 * // before:  https://example.com/hello/?a=1
 * // after:   https://example.com/hello?a=1
 */
app.use("*", async (c: Context, next: Next) => {
  try {
    const url = new URL(c.req.url);
    const pathname = url.pathname;

    // 루트 "/"는 리다이렉트하지 않음
    if (pathname !== "/" && pathname.endsWith("/")) {
      // 경로 끝부분의 중복 슬래시들을 모두 제거
      url.pathname = pathname.replace(/\/+$/, "");

      // 쿼리스트링을 유지한 채로 301 리다이렉트 수행
      return c.redirect(url.pathname + url.search, 301);
    }
  } catch (err) {
    console.error("URL 파싱 중 오류 발생:", err);
  }

  await next();
});

// Request logging middleware
app.use("*", async (c: Context, next: Next) => {
  const start = Date.now();

  await next();

  const duration = Date.now() - start;
  const timestamp = new Date().toISOString();

  // Get original client IP from X-Forwarded-For or fallback
  // TRUST_PROXY 환경 변수로 신뢰할 프록시 개수 설정 (기본값: 1)
  const trustProxy = parseInt(process.env.TRUST_PROXY || "1", 10);
  const forwardedFor = c.req.header("x-forwarded-for");
  let clientIp = getClientIp(forwardedFor, trustProxy);

  // fallback: X-Real-IP 헤더 사용
  if (clientIp === "127.0.0.1" && !forwardedFor) {
    const realIp = c.req.header("x-real-ip");
    if (realIp) {
      clientIp = realIp.replace(/^::ffff:/, "");
      if (clientIp === "::1") {
        clientIp = "127.0.0.1";
      }
    }
  }

  console.log(
    `[${timestamp}] ${clientIp} - ${c.req.method} ${c.req.path} ${c.res.status} - ${duration}ms`
  );
});

app.get("/", (c) => {
  return c.text("💗 HELLO HONO!\n");
});

app.get("/hello", (c) => {
  return c.json({ message: "💗 HELLO HONO FROM JSON!" });
});

app.get("/health", (c) => {
  return c.text("💗 HONO: HELATH CHECK SUCCESS\n", 200);
});

app.get("/api/users/:id", (c) => {
  const id = c.req.param("id");
  return c.json({ id, name: `User ${id}` });
});

app.post("/api/posts", async (c) => {
  const body = await c.req.json();
  return c.json({ message: "Post created!\n", data: body }, 201);
});

// 404 Not Found Handler
app.notFound((c) => {
  return c.json(
    {
      error: "Not Found",
      message: `The requested path '${c.req.path}' does not exist`,
      status: 404,
    },
    404
  );
});

// Error Handlers (비정상 종료)
process.on("uncaughtException", (error) => {
  console.error("Uncaught Exception:", error);
  process.exit(1);
});

process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

const PORT = process.env.PORT || 4000;

const server = Bun.serve({
  port: PORT,
  fetch: app.fetch,
  reusePort: true, // Linux에서 멀티 프로세스 로드 밸런싱 (macOS/Windows는 무시됨)
  development: {
    hmr: true,
    console: true,
  },
});

console.log(`.env $PORT: ${PORT}`);
console.log(
  `Server is running on http://localhost:${PORT} ✅ [PID: ${process.pid}]`
);

// Note: PM2 ready signal은 Bun 런타임에서 IPC 호환성 문제로 비활성화
// Node.js 런타임을 사용할 경우에만 process.send('ready') 활성화 가능

// Graceful Shutdowns (정상 종료)
const gracefulShutdown = () => {
  console.log("Server is shutting down gracefully...");

  // 강제 종료 타임아웃 (10초)
  const forceShutdownTimer = setTimeout(() => {
    console.error("Forced shutdown after timeout");
    process.exit(1);
  }, 10000);

  try {
    server.stop();
    console.log("Server closed");
    clearTimeout(forceShutdownTimer);
    process.exit(0);
  } catch (error) {
    console.error("Error during shutdown:", error);
    clearTimeout(forceShutdownTimer);
    process.exit(1);
  }
};

process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);
