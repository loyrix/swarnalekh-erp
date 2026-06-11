import {
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { createHmac } from 'node:crypto';
import { JwtAuthGuard } from './jwt-auth.guard';

const makeContext = (request: Record<string, any>) =>
  ({
    switchToHttp: () => ({
      getRequest: () => request,
    }),
    getHandler: () => ({}),
    getClass: () => ({}),
  }) as any;

const createGuard = (
  options: {
    isPublic?: boolean;
    secret?: string;
  } = {},
) => {
  const isPublic = options.isPublic ?? false;
  const resolvedSecret = Object.prototype.hasOwnProperty.call(options, 'secret')
    ? options.secret
    : 'test-secret';

  const reflector = {
    getAllAndOverride: jest.fn(() => isPublic),
  } as unknown as Reflector;
  const configService = {
    get: jest.fn((key: string) => {
      if (key === 'AUTH_JWT_SECRET') return resolvedSecret;
      return undefined;
    }),
  } as unknown as ConfigService;

  return new JwtAuthGuard(reflector, configService);
};

const signToken = async (
  secret: string,
  payload: Record<string, unknown> = {},
) => {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: 'HS256', typ: 'JWT' });
  const body = base64UrlJson({
    ...payload,
    sub: 'provider-user-1',
    iss: 'temporary-auth-provider',
    iat: now,
    exp: now + 3600,
  });
  const signature = createHmac('sha256', secret)
    .update(`${header}.${body}`)
    .digest('base64url');

  return `${header}.${body}.${signature}`;
};

const base64UrlJson = (value: Record<string, unknown>) =>
  Buffer.from(JSON.stringify(value)).toString('base64url');

describe('JwtAuthGuard', () => {
  it('allows public routes without a bearer token', async () => {
    const guard = createGuard({ isPublic: true, secret: undefined });
    const request = { headers: {} };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
  });

  it('rejects protected routes without a bearer token', async () => {
    const guard = createGuard();
    const request = { headers: {} };

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('rejects protected routes when the JWT secret is missing', async () => {
    const guard = createGuard({ secret: undefined });
    const token = await signToken('test-secret');
    const request = { headers: { authorization: `Bearer ${token}` } };

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(
      InternalServerErrorException,
    );
  });

  it('attaches a provider-neutral identity for a valid token', async () => {
    const guard = createGuard();
    const token = await signToken('test-secret', {
      email: 'owner@example.com',
      phone: '+919999999999',
      role: 'authenticated',
    });
    const request = { headers: { authorization: `Bearer ${token}` } };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
    expect(request.user).toEqual({
      providerUserId: 'provider-user-1',
      email: 'owner@example.com',
      phone: '+919999999999',
      role: 'authenticated',
      issuer: 'temporary-auth-provider',
    });
  });
});
