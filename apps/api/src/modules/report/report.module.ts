import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';
import { ReportController } from './report.controller.js';
import { ReportService } from './report.service.js';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [ReportController],
  providers: [ReportService],
})
export class ReportModule {}
