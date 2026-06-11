import {
  Injectable,
  ConflictException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RegisterTenantDto, UpdateTenantDto } from './tenant.dto.js';

@Injectable()
export class TenantService {
  constructor(private prisma: PrismaService) {}

  async registerTenant(
    dto: RegisterTenantDto,
    providerUserId: string,
    reqEmail?: string,
  ) {
    const email = reqEmail?.trim().toLowerCase();

    if (!email) {
      throw new BadRequestException(
        'Authenticated email is required for registration.',
      );
    }

    // Check if user already exists
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ authUserId: providerUserId }, { email }],
      },
    });

    if (existingUser) {
      throw new ConflictException(
        'A user with this email is already registered to a shop.',
      );
    }

    // Use a transaction to create Tenant and Owner User together
    return this.prisma.$transaction(async (tx) => {
      // 1. Create the tenant
      const tenant = await tx.tenant.create({
        data: {
          shopName: dto.shopName,
          ownerName: dto.ownerName,
          email,
          city: dto.city,
          state: dto.state,
          gstin: dto.gstin,
          subscriptionPlan: 'free',
        },
      });

      // 2. Create the app user linked to the authenticated provider identity.
      const user = await tx.user.create({
        data: {
          tenantId: tenant.id,
          authUserId: providerUserId,
          name: dto.ownerName,
          email,
          role: 'owner',
          isActive: true,
        },
      });

      return { tenant, user };
    });
  }

  async getProfile(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
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

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    return tenant;
  }

  async updateProfile(tenantId: string, dto: UpdateTenantDto) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: dto,
    });
  }
}
