import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuditLogInterceptor } from './audit-log.interceptor.js';
import { SecurityController } from './security.controller.js';
import { SecurityService } from './security.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [SecurityController],
  providers: [
    SecurityService,
    { provide: APP_INTERCEPTOR, useClass: AuditLogInterceptor },
  ],
  exports: [SecurityService],
})
export class SecurityModule {}
