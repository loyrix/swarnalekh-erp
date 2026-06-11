import { Controller, Get, Query, Request } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ADMIN_ROLES, Roles } from '../../common/decorators/roles.decorator.js';
import { ActivityLogQueryDto } from './security.dto.js';
import { SecurityService } from './security.service.js';

@ApiTags('Security')
@Controller('security')
@ApiBearerAuth()
@Roles(...ADMIN_ROLES)
export class SecurityController {
  constructor(private readonly securityService: SecurityService) {}

  @Get('activity-logs')
  @ApiOperation({ summary: 'List important activity logs for the tenant' })
  async getActivityLogs(
    @Request() req: any,
    @Query() query: ActivityLogQueryDto,
  ) {
    return this.securityService.getActivityLogs(req.tenantId, query);
  }

  @Get('backup')
  @ApiOperation({ summary: 'Export a tenant data backup JSON payload' })
  async createBackup(@Request() req: any) {
    return this.securityService.createBackup(req.tenantId, req.appUser?.id);
  }
}
