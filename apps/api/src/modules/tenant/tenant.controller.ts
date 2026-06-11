import { Controller, Post, Get, Put, Body, Request } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { TenantService } from './tenant.service.js';
import { RegisterTenantDto, UpdateTenantDto } from './tenant.dto.js';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';

@ApiTags('Tenant & Onboarding')
@Controller('tenant')
@ApiBearerAuth('JWT')
export class TenantController {
  constructor(private readonly tenantService: TenantService) {}

  @Post('register')
  @ApiOperation({
    summary: 'Register a new shop (Tenant) after authenticated signup/login',
  })
  @ApiResponse({
    status: 201,
    description: 'Tenant and Owner user created successfully.',
  })
  async register(@Request() req: any, @Body() dto: RegisterTenantDto) {
    return this.tenantService.registerTenant(
      dto,
      req.user.providerUserId,
      req.user.email,
    );
  }

  @Get('profile')
  @Roles(...ALL_APP_ROLES)
  @ApiOperation({ summary: 'Get shop profile (requires active tenant)' })
  async getProfile(@Request() req: any) {
    return this.tenantService.getProfile(req.tenantId);
  }

  @Put('profile')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Update shop profile' })
  async updateProfile(@Request() req: any, @Body() dto: UpdateTenantDto) {
    return this.tenantService.updateProfile(req.tenantId, dto);
  }
}
