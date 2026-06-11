import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface RequestUser {
  providerUserId: string;
  phone?: string;
  email?: string;
  role: string;
  issuer?: string;
}

export interface AuthenticatedUser {
  id: string;
  tenantId: string;
  name: string;
  phone: string | null;
  email: string | null;
  role: string;
  tenant: {
    id: string;
    shopName: string;
    subscriptionPlan: string;
  };
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly prisma: PrismaService) {}

  async resolveUser(authUser: RequestUser): Promise<AuthenticatedUser> {
    const { providerUserId, phone, email } = authUser;
    const normalizedEmail = email?.trim().toLowerCase();

    const user = await this.prisma.user.findFirst({
      where: {
        isActive: true,
        OR: [
          { authUserId: providerUserId },
          normalizedEmail
            ? {
                email: {
                  equals: normalizedEmail,
                  mode: 'insensitive',
                },
              }
            : null,
          phone ? { phone } : null,
        ].filter(Boolean) as any,
      },
      include: {
        tenant: {
          select: {
            id: true,
            shopName: true,
            subscriptionPlan: true,
            isActive: true,
          },
        },
      },
    });

    if (!user) {
      this.logger.warn(
        `Active app user not found for auth subject ${providerUserId} (${normalizedEmail ?? 'no-email'})`,
      );
      throw new UnauthorizedException('User not found or inactive');
    }

    if (!user.tenant.isActive) {
      throw new UnauthorizedException('Tenant account is suspended');
    }

    return {
      id: user.id,
      tenantId: user.tenantId,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      tenant: {
        id: user.tenant.id,
        shopName: user.tenant.shopName,
        subscriptionPlan: user.tenant.subscriptionPlan,
      },
    };
  }
}
