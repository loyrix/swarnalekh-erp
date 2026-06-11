import {
  CanActivate,
  ExecutionContext,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import {
  createHmac,
  createPublicKey,
  timingSafeEqual,
  verify,
  type JsonWebKey,
} from 'node:crypto';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator.js';

type JwtHeader = Record<string, unknown> & {
  alg?: string;
  kid?: string;
};

type DecodedJwt = {
  header: JwtHeader;
  payload: Record<string, unknown>;
  signingInput: string;
  signature: string;
};

type JwksKey = JsonWebKey & {
  kid?: string;
  alg?: string;
  use?: string;
};

type JwksCache = {
  url: string;
  keys: JwksKey[];
  fetchedAt: number;
};

@Injectable()
export class JwtAuthGuard implements CanActivate {
  private static readonly jwksCacheMs = 5 * 60 * 1000;

  private jwksCache: JwksCache | null = null;

  constructor(
    private readonly reflector: Reflector,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const token = this.getBearerToken(request.headers?.authorization);

    try {
      const payload = await this.verifyJwtToken(token);
      const providerUserId = this.getOptionalClaim(payload, 'sub');

      if (!providerUserId) {
        throw new UnauthorizedException('Invalid token subject');
      }

      request.user = {
        providerUserId,
        email:
          this.getOptionalClaim(payload, 'email') ??
          this.getNestedOptionalClaim(payload, 'user_metadata', 'email'),
        phone:
          this.getOptionalClaim(payload, 'phone') ??
          this.getNestedOptionalClaim(payload, 'user_metadata', 'phone'),
        role: this.getOptionalClaim(payload, 'role') ?? 'authenticated',
        issuer: this.getOptionalClaim(payload, 'iss'),
      };

      return true;
    } catch (error) {
      if (
        error instanceof UnauthorizedException ||
        error instanceof InternalServerErrorException
      ) {
        throw error;
      }
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private getBearerToken(authHeader: unknown): string {
    if (typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const token = authHeader.slice('Bearer '.length).trim();
    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    return token;
  }

  private async verifyJwtToken(
    token: string,
  ): Promise<Record<string, unknown>> {
    const decoded = this.decodeJwt(token);
    const algorithm = decoded.header.alg;

    if (algorithm === 'HS256') {
      this.verifyHs256Token(decoded, this.getJwtSecret());
      this.validateTokenTiming(decoded.payload);
      return decoded.payload;
    }

    if (algorithm === 'RS256' || algorithm === 'ES256') {
      await this.verifyJwksToken(decoded);
      this.validateTokenTiming(decoded.payload);
      return decoded.payload;
    }

    throw new UnauthorizedException('Unsupported token algorithm');
  }

  private getJwtSecret(): string {
    const secret =
      this.configService.get<string>('AUTH_JWT_SECRET') ??
      this.configService.get<string>('JWT_SECRET');

    if (!secret) {
      throw new InternalServerErrorException(
        'JWT auth configuration is missing',
      );
    }

    return secret;
  }

  private verifyHs256Token(decoded: DecodedJwt, secret: string): void {
    const expectedSignature = createHmac('sha256', secret)
      .update(decoded.signingInput)
      .digest('base64url');

    if (!this.isSameSignature(decoded.signature, expectedSignature)) {
      throw new UnauthorizedException('Invalid token signature');
    }
  }

  private async verifyJwksToken(decoded: DecodedJwt): Promise<void> {
    const key = await this.getJwksKey(decoded.header);
    const keyObject = createPublicKey({ key, format: 'jwk' });
    const signature = Buffer.from(decoded.signature, 'base64url');
    const input = Buffer.from(decoded.signingInput);
    const verified =
      decoded.header.alg === 'RS256'
        ? verify('RSA-SHA256', input, keyObject, signature)
        : verify(
            'sha256',
            input,
            { key: keyObject, dsaEncoding: 'ieee-p1363' },
            signature,
          );

    if (!verified) {
      throw new UnauthorizedException('Invalid token signature');
    }
  }

  private decodeJwt(token: string): DecodedJwt {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid token format');
    }

    const [encodedHeader, encodedPayload, signature] = parts;
    const header = this.decodeJwtPart(encodedHeader) as JwtHeader;
    const payload = this.decodeJwtPart(encodedPayload);

    if (!header.alg || typeof header.alg !== 'string') {
      throw new UnauthorizedException('Invalid token algorithm');
    }

    if (!signature) {
      throw new UnauthorizedException('Invalid token signature');
    }

    return {
      header,
      payload,
      signingInput: `${encodedHeader}.${encodedPayload}`,
      signature,
    };
  }

  private validateTokenTiming(payload: Record<string, unknown>): void {
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp === 'number' && payload.exp <= now) {
      throw new UnauthorizedException('Token has expired');
    }
    if (typeof payload.nbf === 'number' && payload.nbf > now) {
      throw new UnauthorizedException('Token is not active yet');
    }
  }

  private decodeJwtPart(encoded: string): Record<string, unknown> {
    try {
      return JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
    } catch (_) {
      throw new UnauthorizedException('Invalid token payload');
    }
  }

  private isSameSignature(actual: string, expected: string): boolean {
    const actualBuffer = Buffer.from(actual, 'base64url');
    const expectedBuffer = Buffer.from(expected, 'base64url');
    return (
      actualBuffer.length === expectedBuffer.length &&
      timingSafeEqual(actualBuffer, expectedBuffer)
    );
  }

  private async getJwksKey(header: JwtHeader): Promise<JwksKey> {
    if (!header.kid || typeof header.kid !== 'string') {
      throw new UnauthorizedException('Token signing key is missing');
    }

    const keys = await this.getJwks();
    const key = keys.find(
      (candidate) =>
        candidate.kid === header.kid &&
        (!candidate.alg || candidate.alg === header.alg) &&
        (!candidate.use || candidate.use === 'sig'),
    );

    if (!key) {
      throw new UnauthorizedException('Token signing key is not trusted');
    }

    return key;
  }

  private async getJwks(): Promise<JwksKey[]> {
    const url = this.getJwksUrl();
    const now = Date.now();

    if (
      this.jwksCache?.url === url &&
      now - this.jwksCache.fetchedAt < JwtAuthGuard.jwksCacheMs
    ) {
      return this.jwksCache.keys;
    }

    let response: Response;
    try {
      response = await fetch(url);
    } catch (_) {
      throw new InternalServerErrorException('Unable to load JWT signing keys');
    }

    if (!response.ok) {
      throw new InternalServerErrorException('Unable to load JWT signing keys');
    }

    const body = (await response.json()) as { keys?: unknown };
    if (!Array.isArray(body.keys)) {
      throw new InternalServerErrorException('Invalid JWT signing keys');
    }

    const keys = body.keys.filter(this.isJwksKey);
    this.jwksCache = { url, keys, fetchedAt: now };
    return keys;
  }

  private getJwksUrl(): string {
    const configuredUrl = this.configService.get<string>('AUTH_JWKS_URL');
    if (configuredUrl) {
      return configuredUrl;
    }

    const authProviderUrl = this.configService.get<string>('SUPABASE_URL');
    if (authProviderUrl) {
      return `${authProviderUrl.replace(/\/$/, '')}/auth/v1/.well-known/jwks.json`;
    }

    throw new InternalServerErrorException('JWT auth configuration is missing');
  }

  private isJwksKey(value: unknown): value is JwksKey {
    return Boolean(value && typeof value === 'object' && 'kty' in value);
  }

  private getOptionalClaim(
    payload: Record<string, unknown>,
    key: string,
  ): string | undefined {
    const value = payload[key];
    return typeof value === 'string' && value.trim() ? value : undefined;
  }

  private getNestedOptionalClaim(
    payload: Record<string, unknown>,
    parentKey: string,
    key: string,
  ): string | undefined {
    const parent = payload[parentKey];
    if (!parent || typeof parent !== 'object') {
      return undefined;
    }

    return this.getOptionalClaim(parent as Record<string, unknown>, key);
  }
}
