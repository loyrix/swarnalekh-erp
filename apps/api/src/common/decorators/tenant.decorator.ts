import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Extract the current tenant ID from the request.
 * Must be used after TenantGuard populates req.tenantId.
 *
 * Usage: @TenantId() tenantId: string
 */
export const TenantId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest();
    return request.tenantId;
  },
);

/**
 * Extract the current user from the request.
 * Populated by SupabaseAuthGuard via Passport.
 *
 * Usage: @CurrentUser() user: RequestUser
 */
export const CurrentUser = createParamDecorator(
  (data: string | undefined, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    if (data) {
      return request.user?.[data];
    }
    return request.user;
  },
);
