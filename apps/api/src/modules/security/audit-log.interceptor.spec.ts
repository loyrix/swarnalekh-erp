import { CallHandler, ExecutionContext } from '@nestjs/common';
import { lastValueFrom, of } from 'rxjs';
import { AuditLogInterceptor } from './audit-log.interceptor';
import { SecurityService } from './security.service';

describe('AuditLogInterceptor', () => {
  const createInterceptor = () => {
    const securityService = {
      recordActivity: jest.fn().mockResolvedValue({ id: 'log-1' }),
      sanitizeValue: jest.fn((value) => value),
    };

    return {
      interceptor: new AuditLogInterceptor(
        securityService as unknown as SecurityService,
      ),
      securityService,
    };
  };

  const contextFor = (request: Record<string, unknown>) =>
    ({
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    }) as ExecutionContext;

  const next = (body: unknown): CallHandler => ({
    handle: () => of(body),
  });

  it('records successful mutating tenant activity', async () => {
    const { interceptor, securityService } = createInterceptor();

    await lastValueFrom(
      interceptor.intercept(
        contextFor({
          method: 'POST',
          path: '/api/v1/inventory',
          tenantId: 'tenant-1',
          appUser: { id: 'user-1' },
          body: { itemName: 'Gold Ring' },
          headers: { 'x-forwarded-for': '192.168.0.1, 10.0.0.1' },
          params: {},
        }),
        next({ id: '11111111-1111-4111-8111-111111111111' }),
      ),
    );

    expect(securityService.recordActivity).toHaveBeenCalledWith({
      tenantId: 'tenant-1',
      userId: 'user-1',
      action: 'create',
      entityType: 'inventory',
      entityId: '11111111-1111-4111-8111-111111111111',
      newValues: {
        path: '/inventory',
        body: { itemName: 'Gold Ring' },
        result: {
          id: '11111111-1111-4111-8111-111111111111',
          status: undefined,
        },
      },
      ipAddress: '192.168.0.1',
    });
  });

  it('skips read-only requests', async () => {
    const { interceptor, securityService } = createInterceptor();

    await lastValueFrom(
      interceptor.intercept(
        contextFor({
          method: 'GET',
          path: '/api/v1/inventory',
          tenantId: 'tenant-1',
          appUser: { id: 'user-1' },
          headers: {},
          params: {},
        }),
        next([]),
      ),
    );

    expect(securityService.recordActivity).not.toHaveBeenCalled();
  });
});
