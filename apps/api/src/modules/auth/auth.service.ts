import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import bcrypt from 'bcryptjs';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto, RegisterDto } from './auth.dto';
import { AUTH_TOKEN_TTL_SECONDS, signAuthToken } from './auth.token';

const BCRYPT_ROUNDS = 10;

export interface RequestUser {
  providerUserId: string;
  phone?: string;
  email?: string;
  role: string;
  issuer?: string;
}

export interface AuthSession {
  accessToken: string;
  expiresAt: number;
  tokenType: 'Bearer';
  user: AuthenticatedUser;
}

type UserWithTenant = {
  id: string;
  tenantId: string;
  name: string;
  phone: string | null;
  email: string | null;
  role: string;
  authUserId: string | null;
  passwordHash: string | null;
  tenant: {
    id: string;
    shopName: string;
    subscriptionPlan: string;
    isActive: boolean;
  };
};

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

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Self-owned signup: creates the tenant + its owner user with a hashed
   * password and returns a first-party session (our HS256 JWT). Replaces the
   * Supabase signup + `/tenant/register` two-step.
   */
  async register(dto: RegisterDto): Promise<AuthSession> {
    const email = dto.email.trim().toLowerCase();

    const existing = await this.prisma.user.findFirst({ where: { email } });
    if (existing) {
      throw new ConflictException(
        'A user with this email is already registered.',
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);

    const user = await this.prisma.$transaction(async (tx) => {
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

      return tx.user.create({
        data: {
          tenantId: tenant.id,
          authUserId: randomUUID(),
          name: dto.ownerName,
          email,
          phone: dto.phone,
          role: 'owner',
          passwordHash,
          isActive: true,
        },
        include: this.tenantInclude,
      });
    });

    return this.issueSession(user);
  }

  /** Email + password login → first-party session. */
  async login(dto: LoginDto): Promise<AuthSession> {
    const email = dto.email.trim().toLowerCase();

    const user = await this.prisma.user.findFirst({
      where: {
        isActive: true,
        email: { equals: email, mode: 'insensitive' },
      },
      include: this.tenantInclude,
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'No password set for this account. Ask your shop owner to set one.',
      );
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (!user.tenant.isActive) {
      throw new UnauthorizedException('Tenant account is suspended');
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    return this.issueSession(user);
  }

  async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, BCRYPT_ROUNDS);
  }

  private issueSession(user: UserWithTenant): AuthSession {
    const profile = this.toProfile(user);
    const { token, expiresAt } = signAuthToken(
      {
        sub: user.authUserId ?? user.id,
        email: user.email,
        role: user.role,
        tenantId: user.tenantId,
      },
      this.getJwtSecret(),
      AUTH_TOKEN_TTL_SECONDS,
    );
    return {
      accessToken: token,
      expiresAt,
      tokenType: 'Bearer',
      user: profile,
    };
  }

  private getJwtSecret(): string {
    const secret =
      this.configService.get<string>('AUTH_JWT_SECRET') ??
      this.configService.get<string>('JWT_SECRET');
    if (!secret) {
      throw new InternalServerErrorException(
        'JWT auth configuration is missing',
      );
    }
    return secret;
  }

  private toProfile(user: UserWithTenant): AuthenticatedUser {
    if (!user.email && !user.phone) {
      // Defensive: owner users always have an email; guards against bad seeds.
      throw new BadRequestException('User is missing contact details');
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

  private readonly tenantInclude = {
    tenant: {
      select: {
        id: true,
        shopName: true,
        subscriptionPlan: true,
        isActive: true,
      },
    },
  } as const;

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
