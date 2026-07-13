import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { DashboardController } from './dashboard.controller.js';
import { DashboardService } from './dashboard.service.js';
import { AuthModule } from '../auth/auth.module.js';
import { CategoryModule } from '../category/category.module.js';

@Module({
  imports: [PrismaModule, AuthModule, CategoryModule],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}
