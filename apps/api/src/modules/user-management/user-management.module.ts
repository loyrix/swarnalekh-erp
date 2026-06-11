import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { UserManagementController } from './user-management.controller.js';
import { UserManagementService } from './user-management.service.js';

@Module({
  imports: [PrismaModule],
  controllers: [UserManagementController],
  providers: [UserManagementService],
})
export class UserManagementModule {}
