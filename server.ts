import { Hono } from "hono";
import type { Context, Next } from "hono";

const app = new Hono();

// Remove trailing slashes from URLs (except root "/")
app.use("*", async (c: Context, next: Next) => {
  const path = new URL(c.req.url).pathname;
  if (path !== "/" && path.endsWith("/")) {
    const newPath = path.slice(0, -1);
    const newUrl = new URL(c.req.url);
    newUrl.pathname = newPath;
    return c.redirect(newUrl.toString(), 301);
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
  const forwardedFor = c.req.header("x-forwarded-for");
  let clientIp = forwardedFor
    ? forwardedFor.split(",")[0]?.trim() || "127.0.0.1"
    : c.req.header("x-real-ip") || "127.0.0.1";

  // Convert IPv6 to IPv4 if applicable
  if (clientIp) {
    // Remove IPv6 prefix (::ffff:) for IPv4-mapped addresses
    clientIp = clientIp.replace(/^::ffff:/, "");
    // Convert ::1 (IPv6 localhost) to 127.0.0.1 (IPv4 localhost)
    if (clientIp === "::1") {
      clientIp = "127.0.0.1";
    }
  }

  console.log(
    `[${timestamp}] ${clientIp} - ${c.req.method} ${c.req.path} ${c.res.status} - ${duration}ms`
  );
});

app.get("/", (c) => {
  return c.text("💗 HELLO HONO!\n");
});

app.get("/health", (c) => {
  return c.text("✅ HONO: HELATH CHECK SUCCESS\n", 200);
});

app.get("/api/users/:id", (c) => {
  const id = c.req.param("id");
  return c.json({ id, name: `User ${id}` });
});

app.post("/api/posts", async (c) => {
  const body = await c.req.json();
  return c.json({ message: "Post created!\n", data: body }, 201);
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

const PORT = process.env.PORT || 3001;

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

// PM2 ready signal (fork mode with reusePort)
// PM2가 앱이 준비되었음을 인식하도록 신호 전송
if (process.send) {
  process.send("ready");
}

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
