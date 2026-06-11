import {
  CanActivate,
  ExecutionContext,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator.js';

@Injectable()
export class JwtAuthGuard implements CanActivate {
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
    const secret = this.getJwtSecret();

    try {
      const payload = this.verifyHs256Token(token, secret);
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
      if (error instanceof UnauthorizedException) {
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

  private verifyHs256Token(
    token: string,
    secret: string,
  ): Record<string, unknown> {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid token format');
    }

    const [encodedHeader, encodedPayload, signature] = parts;
    const header = this.decodeJwtPart(encodedHeader);
    if (header.alg !== 'HS256') {
      throw new UnauthorizedException('Unsupported token algorithm');
    }

    const expectedSignature = createHmac('sha256', secret)
      .update(`${encodedHeader}.${encodedPayload}`)
      .digest('base64url');

    if (!this.isSameSignature(signature, expectedSignature)) {
      throw new UnauthorizedException('Invalid token signature');
    }

    const payload = this.decodeJwtPart(encodedPayload);
    const now = Math.floor(Date.now() / 1000);
    if (typeof payload.exp === 'number' && payload.exp <= now) {
      throw new UnauthorizedException('Token has expired');
    }
    if (typeof payload.nbf === 'number' && payload.nbf > now) {
      throw new UnauthorizedException('Token is not active yet');
    }

    return payload;
  }

  private decodeJwtPart(encoded: string): Record<string, unknown> {
    try {
      return JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
    } catch (_) {
      throw new UnauthorizedException('Invalid token payload');
    }
  }

  private isSameSignature(actual: string, expected: string): boolean {
    const actualBuffer = Buffer.from(actual);
    const expectedBuffer = Buffer.from(expected);
    return (
      actualBuffer.length === expectedBuffer.length &&
      timingSafeEqual(actualBuffer, expectedBuffer)
    );
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
