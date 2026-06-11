import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export interface RequestUser {
  supabaseUserId: string;
  phone?: string;
  email?: string;
  role: string;
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

  /**
   * After Supabase JWT is verified, resolve the app-level user
   * by matching the auth provider user ID first, then email/phone.
   */
  async resolveUser(supabaseUser: RequestUser): Promise<AuthenticatedUser> {
    const { supabaseUserId, phone, email } = supabaseUser;
    const normalizedEmail = email?.trim().toLowerCase();

    const user = await this.prisma.user.findFirst({
      where: {
        isActive: true,
        OR: [
          { authUserId: supabaseUserId },
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
        `Active app user not found for Supabase identity ${supabaseUserId} (${normalizedEmail ?? 'no-email'})`,
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
