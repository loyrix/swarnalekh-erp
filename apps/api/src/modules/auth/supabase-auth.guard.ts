import {
  CanActivate,
  ExecutionContext,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { IS_PUBLIC_KEY } from '../../common/decorators/public.decorator.js';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly expectedIssuer: string;
  private jwks: unknown | null = null;

  constructor(
    private reflector: Reflector,
    private configService: ConfigService,
  ) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');

    if (!supabaseUrl) {
      throw new InternalServerErrorException(
        'Supabase auth configuration is missing',
      );
    }

    const normalizedUrl = supabaseUrl.replace(/\/$/, '');
    this.expectedIssuer = `${normalizedUrl}/auth/v1`;
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if route is marked @Public()
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const token = authHeader.slice('Bearer '.length).trim();
    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    try {
      const { jwtVerify } = await import('jose');
      const jwks = await this.getJwks();

      const { payload } = await jwtVerify(token, jwks as any, {
        issuer: this.expectedIssuer,
      });

      if (!payload?.sub) {
        throw new UnauthorizedException('Invalid token');
      }

      request.user = {
        supabaseUserId: payload.sub,
        phone: this.getOptionalClaim(payload, 'phone'),
        email: this.getOptionalClaim(payload, 'email'),
        role: payload.role ?? 'authenticated',
      };

      return true;
    } catch (_) {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  private async getJwks() {
    if (this.jwks) {
      return this.jwks;
    }

    const { createRemoteJWKSet } = await import('jose');
    this.jwks = createRemoteJWKSet(
      new URL(`${this.expectedIssuer}/.well-known/jwks.json`),
    );
    return this.jwks;
  }

  private getOptionalClaim(payload: Record<string, unknown>, key: string): string | undefined {
    const value = payload[key];
    return typeof value === 'string' ? value : undefined;
  }
}
