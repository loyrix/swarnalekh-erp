import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';
import { UserManagementController } from './user-management.controller.js';
import { UserManagementService } from './user-management.service.js';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [UserManagementController],
  providers: [UserManagementService],
})
export class UserManagementModule {}
