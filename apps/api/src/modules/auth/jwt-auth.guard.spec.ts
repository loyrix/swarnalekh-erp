import {
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import {
  createHmac,
  generateKeyPairSync,
  sign,
  type JsonWebKey,
  type KeyObject,
} from 'node:crypto';
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
    jwksUrl?: string;
    supabaseUrl?: string;
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
      if (key === 'AUTH_JWKS_URL') return options.jwksUrl;
      if (key === 'SUPABASE_URL') return options.supabaseUrl;
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

const signRs256Token = (
  privateKey: KeyObject,
  kid: string,
  payload: Record<string, unknown> = {},
) => {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: 'RS256', typ: 'JWT', kid });
  const body = base64UrlJson({
    ...payload,
    sub: 'provider-user-rsa',
    iss: 'jwks-auth-provider',
    iat: now,
    exp: now + 3600,
  });
  const signature = sign(
    'RSA-SHA256',
    Buffer.from(`${header}.${body}`),
    privateKey,
  ).toString('base64url');

  return `${header}.${body}.${signature}`;
};

const base64UrlJson = (value: Record<string, unknown>) =>
  Buffer.from(JSON.stringify(value)).toString('base64url');

describe('JwtAuthGuard', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

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

  it('attaches a provider-neutral identity for a valid JWKS token', async () => {
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });
    const jwk = publicKey.export({ format: 'jwk' }) as JsonWebKey & {
      kid: string;
      alg: string;
      use: string;
    };
    jwk.kid = 'rsa-test-key';
    jwk.alg = 'RS256';
    jwk.use = 'sig';
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: async () => ({ keys: [jwk] }),
    } as Response);
    const guard = createGuard({
      secret: undefined,
      jwksUrl: 'https://auth.example.test/.well-known/jwks.json',
    });
    const token = signRs256Token(privateKey, jwk.kid, {
      email: 'owner-rsa@example.com',
      role: 'authenticated',
    });
    const request = { headers: { authorization: `Bearer ${token}` } };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
    expect(fetchMock).toHaveBeenCalledWith(
      'https://auth.example.test/.well-known/jwks.json',
    );
    expect(request.user).toEqual({
      providerUserId: 'provider-user-rsa',
      email: 'owner-rsa@example.com',
      phone: undefined,
      role: 'authenticated',
      issuer: 'jwks-auth-provider',
    });
  });

  it('derives a temporary JWKS URL from the existing auth provider URL', async () => {
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });
    const jwk = publicKey.export({ format: 'jwk' }) as JsonWebKey & {
      kid: string;
      alg: string;
      use: string;
    };
    jwk.kid = 'supabase-rsa-test-key';
    jwk.alg = 'RS256';
    jwk.use = 'sig';
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: async () => ({ keys: [jwk] }),
    } as Response);
    const guard = createGuard({
      secret: undefined,
      supabaseUrl: 'https://project-ref.supabase.co/',
    });
    const token = signRs256Token(privateKey, jwk.kid);
    const request = { headers: { authorization: `Bearer ${token}` } };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
    expect(fetchMock).toHaveBeenCalledWith(
      'https://project-ref.supabase.co/auth/v1/.well-known/jwks.json',
    );
  });
});
