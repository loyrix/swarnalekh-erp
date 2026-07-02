import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import bcrypt from 'bcryptjs';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';

const SECRET = 'unit-secret';
const tenant = {
  id: 't1',
  shopName: 'Shop',
  subscriptionPlan: 'free',
  isActive: true,
};

const createService = () => {
  const prisma = {
    user: { findFirst: jest.fn(), update: jest.fn() },
    $transaction: jest.fn(),
  };
  const config = {
    get: jest.fn((key: string) =>
      key === 'AUTH_JWT_SECRET' ? SECRET : undefined,
    ),
  };
  return {
    prisma,
    service: new AuthService(
      prisma as unknown as PrismaService,
      config as unknown as ConfigService,
    ),
  };
};

describe('AuthService — email/password', () => {
  describe('register', () => {
    it('creates a tenant + owner and returns a session token', async () => {
      const { service, prisma } = createService();
      prisma.user.findFirst.mockResolvedValue(null);
      prisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          tenant: { create: jest.fn().mockResolvedValue({ id: 't1' }) },
          user: {
            create: jest.fn().mockResolvedValue({
              id: 'u1',
              tenantId: 't1',
              name: 'Owner',
              email: 'o@x.com',
              phone: null,
              role: 'owner',
              authUserId: 'sub-1',
              passwordHash: 'h',
              tenant,
            }),
          },
        }),
      );

      const session = await service.register({
        shopName: 'Shop',
        ownerName: 'Owner',
        email: 'O@x.com',
        password: 'password1',
      });

      expect(session.accessToken.split('.')).toHaveLength(3);
      expect(session.tokenType).toBe('Bearer');
      expect(session.user).toMatchObject({
        id: 'u1',
        role: 'owner',
        email: 'o@x.com',
      });
    });

    it('rejects a duplicate email', async () => {
      const { service, prisma } = createService();
      prisma.user.findFirst.mockResolvedValue({ id: 'existing' });
      await expect(
        service.register({
          shopName: 'S',
          ownerName: 'O',
          email: 'o@x.com',
          password: 'password1',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    const withUser = async (over: Record<string, unknown> = {}) => {
      const ctx = createService();
      const passwordHash = await bcrypt.hash('password1', 10);
      ctx.prisma.user.findFirst.mockResolvedValue({
        id: 'u1',
        tenantId: 't1',
        name: 'Owner',
        email: 'o@x.com',
        phone: null,
        role: 'owner',
        authUserId: 'sub-1',
        passwordHash,
        tenant,
        ...over,
      });
      ctx.prisma.user.update.mockResolvedValue({});
      return ctx;
    };

    it('returns a session and stamps lastLoginAt on valid credentials', async () => {
      const { service, prisma } = await withUser();
      const session = await service.login({
        email: 'o@x.com',
        password: 'password1',
      });
      expect(session.user.id).toBe('u1');
      expect(prisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'u1' },
          data: expect.objectContaining({ lastLoginAt: expect.any(Date) }),
        }),
      );
    });

    it('rejects a wrong password', async () => {
      const { service } = await withUser();
      await expect(
        service.login({ email: 'o@x.com', password: 'wrong-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects an unknown email', async () => {
      const { service, prisma } = createService();
      prisma.user.findFirst.mockResolvedValue(null);
      await expect(
        service.login({ email: 'nobody@x.com', password: 'x' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects a migrated user with no password set', async () => {
      const { service } = await withUser({ passwordHash: null });
      await expect(
        service.login({ email: 'o@x.com', password: 'anything' }),
      ).rejects.toThrow(/no password set/i);
    });

    it('rejects a suspended tenant', async () => {
      const { service } = await withUser({
        tenant: { ...tenant, isActive: false },
      });
      await expect(
        service.login({ email: 'o@x.com', password: 'password1' }),
      ).rejects.toThrow(/suspended/i);
    });
  });
});
