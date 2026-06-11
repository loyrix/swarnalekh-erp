import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { SecurityService } from './security.service.js';

const MUTATING_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

@Injectable()
export class AuditLogInterceptor implements NestInterceptor {
  constructor(private readonly securityService: SecurityService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();

    return next.handle().pipe(
      tap((responseBody) => {
        const entry = this.buildEntry(request, responseBody);
        if (!entry) return;
        void this.securityService.recordActivity(entry).catch(() => undefined);
      }),
    );
  }

  private buildEntry(request: any, responseBody: unknown) {
    const method = String(request.method ?? '').toUpperCase();
    if (!MUTATING_METHODS.has(method)) return null;

    const tenantId = request.tenantId;
    if (!tenantId) return null;

    const path = this.normalizedPath(request);
    if (path.startsWith('/security/activity-logs')) return null;

    const entityType = this.entityTypeFromPath(path);
    const resultId = this.resultId(responseBody);

    return {
      tenantId,
      userId: request.appUser?.id ?? null,
      action: this.actionFor(method, path),
      entityType,
      entityId: request.params?.id ?? resultId ?? null,
      newValues: {
        path,
        body: this.securityService.sanitizeValue(request.body ?? null),
        result: this.securityService.sanitizeValue({
          id: resultId,
          status:
            responseBody && typeof responseBody === 'object'
              ? (responseBody as Record<string, unknown>)['status']
              : undefined,
        }),
      },
      ipAddress: this.ipAddress(request),
    };
  }

  private normalizedPath(request: any) {
    const rawPath = String(request.path ?? request.url ?? '');
    return rawPath.replace(/^\/api\/v1/, '') || '/';
  }

  private entityTypeFromPath(path: string) {
    const [first, second] = path.split('/').filter(Boolean);
    if (first === 'tenant' && second === 'profile') return 'tenant';
    if (first === 'daily-rates') return 'daily_rate';
    if (first === 'mortgages') {
      return second === undefined || this.isUuid(second) ? 'mortgage' : second;
    }
    return (first ?? 'system').replace(/-/g, '_');
  }

  private actionFor(method: string, path: string) {
    if (path.includes('/payments')) return 'payment';
    if (path.endsWith('/close')) return 'close';
    if (method === 'POST') return 'create';
    if (method === 'PUT' || method === 'PATCH') return 'update';
    if (method === 'DELETE') return 'delete';
    return method.toLowerCase();
  }

  private resultId(responseBody: unknown) {
    if (!responseBody || typeof responseBody !== 'object') return null;
    const id = (responseBody as Record<string, unknown>)['id'];
    return typeof id === 'string' ? id : null;
  }

  private ipAddress(request: any) {
    const forwarded = request.headers?.['x-forwarded-for'];
    if (typeof forwarded === 'string' && forwarded.trim()) {
      return forwarded.split(',')[0].trim();
    }
    return request.ip ?? request.socket?.remoteAddress ?? null;
  }

  private isUuid(value: unknown): value is string {
    return (
      typeof value === 'string' &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        value,
      )
    );
  }
}
