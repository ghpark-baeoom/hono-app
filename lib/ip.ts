/**
 * X-Forwarded-For 헤더에서 신뢰할 프록시 개수를 기반으로 클라이언트 IP 추출
 * Express의 app.set('trust proxy', N)과 동일한 동작
 *
 * @param forwardedFor - X-Forwarded-For 헤더 값 (쉼표로 구분된 IP 목록)
 * @param trustProxy - 신뢰할 프록시 개수 (기본값: 1)
 *   - 0: 프록시를 신뢰하지 않음 → 마지막 IP (리버스 프록시의 IP)
 *   - 1: 직접 프록시(Nginx)만 신뢰 → 그 앞의 IP
 *   - 2: Nginx + ALB 신뢰
 *   - 3: Nginx + ALB + Cloudflare 신뢰
 *
 * @example
 * // X-Forwarded-For: 203.0.113.45, 172.31.10.25, 10.0.1.12, 127.0.0.1
 * getClientIp("203.0.113.45, 172.31.10.25, 10.0.1.12, 127.0.0.1", 1)
 * // → "10.0.1.12" (Nginx만 신뢰)
 *
 * getClientIp("203.0.113.45, 172.31.10.25, 10.0.1.12, 127.0.0.1", 2)
 * // → "172.31.10.25" (Nginx + ALB 신뢰)
 *
 * @example
 * // 환경 변수로 trustProxy 설정
 * const TRUST_PROXY = parseInt(process.env.TRUST_PROXY || "1", 10);
 * const clientIp = getClientIp(forwardedFor, TRUST_PROXY);
 */
export function getClientIp(
  forwardedFor: string | undefined,
  trustProxy: number = 1
): string {
  if (!forwardedFor) {
    return "127.0.0.1";
  }

  const ips = forwardedFor
    .split(",")
    .map((ip) => ip.trim())
    .filter((ip) => ip.length > 0);

  if (ips.length === 0) {
    return "127.0.0.1";
  }

  // trustProxy개 만큼 오른쪽에서 제거
  const clientIpIndex = Math.max(0, ips.length - trustProxy - 1);
  let clientIp = ips[clientIpIndex] || "127.0.0.1";

  // IPv6 to IPv4 변환
  clientIp = clientIp.replace(/^::ffff:/, "");
  if (clientIp === "::1") {
    clientIp = "127.0.0.1";
  }

  return clientIp;
}
