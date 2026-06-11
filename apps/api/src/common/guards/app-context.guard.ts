import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { AuthService } from '../../modules/auth/auth.service.js';

@Injectable()
export class AppContextGuard implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    if (!request.user) {
      return true;
    }

    if (!request.appUser) {
      try {
        const appUser = await this.authService.resolveUser(request.user);
        request.appUser = appUser;
        request.tenantId = appUser.tenantId;
      } catch (_) {
        const path = String(request.path ?? request.url ?? '');
        const isRegistrationRoute = path.endsWith('/tenant/register');
        const isAuthMeRoute = path.endsWith('/auth/me');

        if (isRegistrationRoute || isAuthMeRoute) {
          return true;
        }

        throw new ForbiddenException(
          'Complete shop registration to access this resource',
        );
      }
    }

    return true;
  }
}
