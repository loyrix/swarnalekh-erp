import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator.js';
import { ROLES_KEY } from '../decorators/roles.decorator.js';
import { AuthService } from '../../modules/auth/auth.service.js';

/**
 * Guard that:
 * 1. Resolves the full app user from Supabase JWT
 * 2. Attaches user + tenantId to request
 * 3. Checks role-based access if @Roles() is set
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private authService: AuthService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // 1. Check for @Public decorator
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest();

    // 2. Check for @Roles decorator
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    // If no user from Passport, and no roles required, just let it through
    // (Actual Passport authentication is handled by the global SupabaseAuthGuard)
    if (!request.user) {
      if (!requiredRoles || requiredRoles.length === 0) return true;
      throw new ForbiddenException('Authentication required');
    }

    // 3. Resolve app user from Supabase JWT and cache it on the request.
    if (!request.appUser && request.user) {
      try {
        const appUser = await this.authService.resolveUser(request.user);
        request.appUser = appUser;
        request.tenantId = appUser.tenantId;
      } catch (_) {
        if (requiredRoles && requiredRoles.length > 0) {
          throw new ForbiddenException(
            'Complete shop registration to access this resource',
          );
        }
      }
    }

    // 4. Role enforcement
    if (!requiredRoles || requiredRoles.length === 0) {
      return true; // No roles required, and we tried to resolve user (optional)
    }

    // If roles ARE required, we MUST have a resolved appUser
    if (!request.appUser) {
      throw new ForbiddenException('User profile not found in database');
    }

    const userRole = String(request.appUser.role ?? '').toLowerCase();
    const allowedRoles = requiredRoles.map((role) => role.toLowerCase());

    if (!allowedRoles.includes(userRole)) {
      throw new ForbiddenException(
        `Role '${request.appUser.role}' cannot access this resource`,
      );
    }

    return true;
  }
}
