import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';
import {
  CreateManagedUserDto,
  ManagedUserQueryDto,
  UpdateManagedUserDto,
} from './user-management.dto.js';

const managedUserSelect = {
  id: true,
  name: true,
  email: true,
  phone: true,
  role: true,
  isActive: true,
  lastLoginAt: true,
  createdAt: true,
  authUserId: true,
} satisfies Prisma.UserSelect;

type ManagedUser = Prisma.UserGetPayload<{ select: typeof managedUserSelect }>;

@Injectable()
export class UserManagementService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(tenantId: string, query: ManagedUserQueryDto = {}) {
    const search = query.search?.trim();
    const users = await this.prisma.user.findMany({
      where: {
        tenantId,
        ...(search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { email: { contains: search, mode: 'insensitive' } },
                { phone: { contains: search } },
                { role: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      select: managedUserSelect,
      orderBy: [{ isActive: 'desc' }, { createdAt: 'asc' }],
    });

    return users.map((user) => this.toResponse(user));
  }

  async create(tenantId: string, dto: CreateManagedUserDto) {
    const email = this.normalizeEmail(dto.email);
    const phone = this.normalizeOptional(dto.phone);

    await this.ensureEmailAvailable(email);
    await this.ensureTenantPhoneAvailable(tenantId, phone);

    const user = await this.prisma.user.create({
      data: {
        tenantId,
        name: dto.name.trim(),
        email,
        phone,
        role: dto.role,
        isActive: true,
      },
      select: managedUserSelect,
    });

    return this.toResponse(user);
  }

  async update(
    tenantId: string,
    actorUserId: string,
    id: string,
    dto: UpdateManagedUserDto,
  ) {
    const existing = await this.findTenantUser(tenantId, id);
    this.assertOwnerIsProtected(existing, dto);
    this.assertSelfIsProtected(actorUserId, id, dto);

    const email =
      dto.email === undefined ? undefined : this.normalizeEmail(dto.email);
    const phone =
      dto.phone === undefined ? undefined : this.normalizeOptional(dto.phone);

    if (email !== undefined && email !== existing.email) {
      await this.ensureEmailAvailable(email, id);
    }
    if (phone !== undefined && phone !== existing.phone) {
      await this.ensureTenantPhoneAvailable(tenantId, phone, id);
    }

    const user = await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(email !== undefined ? { email } : {}),
        ...(phone !== undefined ? { phone } : {}),
        ...(dto.role !== undefined ? { role: dto.role } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      select: managedUserSelect,
    });

    return this.toResponse(user);
  }

  async deactivate(tenantId: string, actorUserId: string, id: string) {
    const existing = await this.findTenantUser(tenantId, id);
    this.assertOwnerIsProtected(existing, { isActive: false });
    this.assertSelfIsProtected(actorUserId, id, { isActive: false });

    const user = await this.prisma.user.update({
      where: { id },
      data: { isActive: false },
      select: managedUserSelect,
    });

    return this.toResponse(user);
  }

  private async findTenantUser(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({
      where: { tenantId, id },
      select: managedUserSelect,
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async ensureEmailAvailable(email: string, excludeId?: string) {
    const existing = await this.prisma.user.findFirst({
      where: {
        email,
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException('A user with this email already exists');
    }
  }

  private async ensureTenantPhoneAvailable(
    tenantId: string,
    phone?: string | null,
    excludeId?: string,
  ) {
    if (!phone) return;

    const existing = await this.prisma.user.findFirst({
      where: {
        tenantId,
        phone,
        ...(excludeId ? { id: { not: excludeId } } : {}),
      },
      select: { id: true },
    });

    if (existing) {
      throw new ConflictException('A user with this phone already exists');
    }
  }

  private assertOwnerIsProtected(
    user: ManagedUser,
    dto: Pick<UpdateManagedUserDto, 'role' | 'isActive'>,
  ) {
    if (user.role !== 'owner') return;

    if (dto.role !== undefined || dto.isActive === false) {
      throw new BadRequestException(
        'Owner role cannot be changed or deactivated',
      );
    }
  }

  private assertSelfIsProtected(
    actorUserId: string,
    targetUserId: string,
    dto: Pick<UpdateManagedUserDto, 'isActive'>,
  ) {
    if (actorUserId === targetUserId && dto.isActive === false) {
      throw new BadRequestException('You cannot deactivate your own user');
    }
  }

  private normalizeEmail(value: string | null | undefined) {
    const email = value?.trim().toLowerCase();
    if (!email) {
      throw new BadRequestException('Email is required');
    }
    return email;
  }

  private normalizeOptional(value: string | null | undefined) {
    const normalized = value?.trim();
    return normalized ? normalized : null;
  }

  private toResponse(user: ManagedUser) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      authLinked: Boolean(user.authUserId),
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
    };
  }
}
