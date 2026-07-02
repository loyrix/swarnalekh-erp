import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { CustomerModule } from './modules/customer/customer.module.js';
import { InventoryModule } from './modules/inventory/inventory.module.js';
import { DailyRateModule } from './modules/daily-rate/daily-rate.module.js';
import { InvoiceModule } from './modules/invoice/invoice.module.js';
import { JwtAuthGuard } from './modules/auth/jwt-auth.guard.js';
import { AppContextGuard } from './common/guards/app-context.guard.js';
import { RolesGuard } from './common/guards/roles.guard.js';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { TenantModule } from './modules/tenant/tenant.module.js';
import { DashboardModule } from './modules/dashboard/dashboard.module.js';
import { MortgageModule } from './modules/mortgage/mortgage.module.js';
import { ReportModule } from './modules/report/report.module.js';
import { SecurityModule } from './modules/security/security.module.js';
import { UserManagementModule } from './modules/user-management/user-management.module.js';
import { ExportModule } from './modules/export/export.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    PrismaModule,
    AuthModule,
    CustomerModule,
    InventoryModule,
    DailyRateModule,
    InvoiceModule,
    MortgageModule,
    ReportModule,
    SecurityModule,
    UserManagementModule,
    TenantModule,
    DashboardModule,
    ExportModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Global guards (order matters: auth first, then app context)
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: AppContextGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
