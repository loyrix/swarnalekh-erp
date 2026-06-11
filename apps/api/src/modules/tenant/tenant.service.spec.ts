import { NotFoundException } from '@nestjs/common';
import { TenantService } from './tenant.service';

describe('TenantService', () => {
  const tenant = {
    id: 'tenant-1',
    shopName: 'Kundan Jewellers',
    ownerName: 'Owner',
    phone: '+919876543210',
    users: [],
  };

  const createService = () => {
    const prisma = {
      tenant: {
        update: jest.fn().mockResolvedValue(tenant),
        findUnique: jest.fn().mockResolvedValue(tenant),
      },
    };

    return {
      prisma,
      service: new TenantService(prisma as any),
    };
  };

  it('updates tenant phone and returns the full profile', async () => {
    const { prisma, service } = createService();

    await expect(
      service.updateProfile('tenant-1', {
        shopName: 'Kundan Jewellers',
        phone: '+919876543210',
      }),
    ).resolves.toEqual(tenant);

    expect(prisma.tenant.update).toHaveBeenCalledWith({
      where: { id: 'tenant-1' },
      data: {
        shopName: 'Kundan Jewellers',
        phone: '+919876543210',
      },
    });
    expect(prisma.tenant.findUnique).toHaveBeenCalledWith({
      where: { id: 'tenant-1' },
      include: {
        users: {
          select: {
            id: true,
            name: true,
            role: true,
            phone: true,
            email: true,
          },
        },
      },
    });
  });

  it('throws when the profile cannot be found after update', async () => {
    const { prisma, service } = createService();
    prisma.tenant.findUnique.mockResolvedValue(null);

    await expect(
      service.updateProfile('missing-tenant', {
        phone: '+919876543210',
      }),
    ).rejects.toThrow(NotFoundException);
  });
});
