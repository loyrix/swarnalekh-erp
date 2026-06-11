import { Module } from '@nestjs/common';
import { InvoiceController } from './invoice.controller.js';
import { InvoiceService } from './invoice.service.js';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [InvoiceController],
  providers: [InvoiceService],
})
export class InvoiceModule {}
