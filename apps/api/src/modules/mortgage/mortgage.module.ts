import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';
import { MortgageController } from './mortgage.controller.js';
import { MortgageService } from './mortgage.service.js';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [MortgageController],
  providers: [MortgageService],
})
export class MortgageModule {}
