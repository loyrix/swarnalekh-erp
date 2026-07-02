import { BadRequestException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from '../auth/auth.service';
import { UserManagementService } from './user-management.service';

describe('UserManagementService', () => {
  const createService = () => {
    const prisma = {
      user: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };
    const authService = {
      hashPassword: jest.fn().mockResolvedValue('hashed-password'),
    };

    return {
      service: new UserManagementService(
        prisma as unknown as PrismaService,
        authService as unknown as AuthService,
      ),
      prisma,
      authService,
    };
  };

  const userRow = (overrides: Record<string, unknown> = {}) => ({
    id: 'user-1',
    name: 'Asha',
    email: 'asha@example.com',
    phone: '+919999000111',
    role: 'staff',
    isActive: true,
    authUserId: null,
    lastLoginAt: null,
    createdAt: new Date('2026-06-10T00:00:00.000Z'),
    ...overrides,
  });

  it('lists tenant users with PDF role and login status fields', async () => {
    const { service, prisma } = createService();
    prisma.user.findMany.mockResolvedValue([
      userRow({ authUserId: '11111111-1111-4111-8111-111111111111' }),
    ]);

    await expect(
      service.findAll('tenant-1', { search: 'asha' }),
    ).resolves.toEqual([
      {
        id: 'user-1',
        name: 'Asha',
        email: 'asha@example.com',
        phone: '+919999000111',
        role: 'staff',
        isActive: true,
        authLinked: true,
        lastLoginAt: null,
        createdAt: new Date('2026-06-10T00:00:00.000Z'),
      },
    ]);
    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          tenantId: 'tenant-1',
          OR: expect.any(Array),
        }),
      }),
    );
  });

  it('creates staff or admin users with normalized email', async () => {
    const { service, prisma } = createService();
    prisma.user.findFirst.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue(
      userRow({ email: 'asha@example.com', role: 'admin' }),
    );

    const created = await service.create('tenant-1', {
      name: 'Asha',
      email: '  ASHA@example.com ',
      phone: ' +919999000111 ',
      role: 'admin',
    });

    expect(created).toMatchObject({
      email: 'asha@example.com',
      role: 'admin',
      authLinked: false,
    });
    expect(prisma.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          tenantId: 'tenant-1',
          email: 'asha@example.com',
          phone: '+919999000111',
          role: 'admin',
          isActive: true,
        }),
      }),
    );
  });

  it('hashes an initial password and assigns a login subject', async () => {
    const { service, prisma, authService } = createService();
    prisma.user.findFirst.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue(userRow());

    await service.create('tenant-1', {
      name: 'Asha',
      email: 'asha@example.com',
      role: 'staff',
      password: 'super-secret',
    });

    expect(authService.hashPassword).toHaveBeenCalledWith('super-secret');
    const data = prisma.user.create.mock.calls[0][0].data;
    expect(data.passwordHash).toBe('hashed-password');
    expect(typeof data.authUserId).toBe('string');
  });

  it('does not set a password subject when none is provided', async () => {
    const { service, prisma, authService } = createService();
    prisma.user.findFirst.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue(userRow());

    await service.create('tenant-1', {
      name: 'Asha',
      email: 'asha@example.com',
      role: 'staff',
    });

    expect(authService.hashPassword).not.toHaveBeenCalled();
    const data = prisma.user.create.mock.calls[0][0].data;
    expect(data.passwordHash).toBeUndefined();
    expect(data.authUserId).toBeUndefined();
  });

  it('sets/resets a password and keeps an existing login subject', async () => {
    const { service, prisma, authService } = createService();
    prisma.user.findFirst.mockResolvedValue(
      userRow({ id: 'user-1', authUserId: 'existing-subject' }),
    );
    prisma.user.update.mockResolvedValue(userRow({ id: 'user-1' }));

    await service.setPassword('tenant-1', 'user-1', 'new-password');

    expect(authService.hashPassword).toHaveBeenCalledWith('new-password');
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          passwordHash: 'hashed-password',
          authUserId: 'existing-subject',
        }),
      }),
    );
  });

  it('rejects duplicate user emails', async () => {
    const { service, prisma } = createService();
    prisma.user.findFirst.mockResolvedValue({ id: 'existing-user' });

    await expect(
      service.create('tenant-1', {
        name: 'Asha',
        email: 'asha@example.com',
        role: 'staff',
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('prevents owner demotion or deactivation', async () => {
    const { service, prisma } = createService();
    prisma.user.findFirst.mockResolvedValue(userRow({ role: 'owner' }));

    await expect(
      service.update('tenant-1', 'actor-1', 'user-1', { role: 'staff' }),
    ).rejects.toThrow(BadRequestException);

    await expect(
      service.deactivate('tenant-1', 'actor-1', 'user-1'),
    ).rejects.toThrow(BadRequestException);
  });

  it('prevents admins from deactivating themselves', async () => {
    const { service, prisma } = createService();
    prisma.user.findFirst.mockResolvedValue(userRow({ id: 'user-1' }));

    await expect(
      service.update('tenant-1', 'user-1', 'user-1', { isActive: false }),
    ).rejects.toThrow(BadRequestException);
  });
});
