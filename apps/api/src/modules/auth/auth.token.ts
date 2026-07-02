import { createHmac } from 'node:crypto';

export interface AuthTokenClaims {
  sub: string;
  email?: string | null;
  role: string;
  tenantId: string;
}

/** 30 days — long-lived access token for a shop-floor app (re-login on expiry). */
export const AUTH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30;

/**
 * Signs an HS256 JWT that `JwtAuthGuard`'s HS256 path verifies with the same
 * `AUTH_JWT_SECRET`. Kept pure and dependency-free so it mirrors the guard's
 * verification and is trivially unit-testable.
 */
export function signAuthToken(
  claims: AuthTokenClaims,
  secret: string,
  expiresInSeconds: number = AUTH_TOKEN_TTL_SECONDS,
  now: number = Math.floor(Date.now() / 1000),
): { token: string; expiresAt: number } {
  const exp = now + expiresInSeconds;
  const encodedHeader = base64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const encodedPayload = base64url(
    JSON.stringify({
      sub: claims.sub,
      email: claims.email ?? undefined,
      role: claims.role,
      tenantId: claims.tenantId,
      iss: 'swarnalekh',
      iat: now,
      exp,
    }),
  );
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = createHmac('sha256', secret)
    .update(signingInput)
    .digest('base64url');
  return { token: `${signingInput}.${signature}`, expiresAt: exp };
}

function base64url(input: string): string {
  return Buffer.from(input, 'utf8').toString('base64url');
}
