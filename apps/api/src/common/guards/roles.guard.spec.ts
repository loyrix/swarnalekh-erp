import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from '../../modules/auth/auth.service';
import { RolesGuard } from './roles.guard';

const makeContext = (request: Record<string, unknown>) =>
  ({
    switchToHttp: () => ({
      getRequest: () => request,
    }),
    getHandler: () => ({}),
    getClass: () => ({}),
  }) as any;

describe('RolesGuard', () => {
  const createGuard = (requiredRoles?: string[]) => {
    const reflector = {
      getAllAndOverride: jest.fn((key: string) => {
        if (key === 'roles') return requiredRoles;
        return false;
      }),
    } as unknown as Reflector;

    const authService = {
      resolveUser: jest.fn(),
    } as unknown as AuthService;

    return new RolesGuard(reflector, authService);
  };

  it('allows Admin-equivalent owner role for Admin routes', async () => {
    const guard = createGuard(['owner', 'admin']);
    const request = {
      user: { supabaseUserId: 'auth-1' },
      appUser: { role: 'owner' },
    };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
  });

  it('rejects Staff role for Admin-only routes', async () => {
    const guard = createGuard(['owner', 'admin']);
    const request = {
      user: { supabaseUserId: 'auth-1' },
      appUser: { role: 'staff' },
    };

    await expect(guard.canActivate(makeContext(request))).rejects.toThrow(
      ForbiddenException,
    );
  });

  it('allows Staff role for Staff-enabled routes', async () => {
    const guard = createGuard(['owner', 'admin', 'staff']);
    const request = {
      user: { supabaseUserId: 'auth-1' },
      appUser: { role: 'staff' },
    };

    await expect(guard.canActivate(makeContext(request))).resolves.toBe(true);
  });
});
