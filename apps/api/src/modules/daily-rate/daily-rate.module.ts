import { Module } from '@nestjs/common';
import { DailyRateController } from './daily-rate.controller.js';
import { DailyRateService } from './daily-rate.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [DailyRateController],
  providers: [DailyRateService],
})
export class DailyRateModule {}
