import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

export interface SupabaseJwtPayload {
  sub: string; // Supabase user ID
  email?: string;
  phone?: string;
  role: string; // 'authenticated' | 'anon'
  aud: string;
  iss: string;
  iat: number;
  exp: number;
  app_metadata?: {
    provider?: string;
  };
  user_metadata?: Record<string, any>;
}

@Injectable()
export class SupabaseStrategy extends PassportStrategy(Strategy, 'supabase') {
  constructor(configService: ConfigService) {
    const jwtSecret = configService.get<string>('JWT_SECRET');
    if (!jwtSecret) {
      throw new Error('JWT_SECRET not configured');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: jwtSecret,
    });
  }

  async validate(payload: SupabaseJwtPayload) {
    if (!payload.sub) {
      throw new UnauthorizedException('Invalid token');
    }

    return {
      supabaseUserId: payload.sub,
      phone: payload.phone,
      email: payload.email,
      role: payload.role,
    };
  }
}
