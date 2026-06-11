import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';
export const ADMIN_ROLES = ['owner', 'admin'] as const;
export const STAFF_ROLES = ['staff'] as const;
export const ALL_APP_ROLES = [...ADMIN_ROLES, ...STAFF_ROLES] as const;

export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
