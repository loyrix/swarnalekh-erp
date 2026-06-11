import { Controller, Get, Request } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { DashboardService } from './dashboard.service.js';
import {
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';

@ApiTags('Dashboard')
@Controller('dashboard')
@ApiBearerAuth('JWT')
@Roles(...ALL_APP_ROLES)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('bootstrap')
  @ApiOperation({
    summary: 'Get dashboard bootstrap data for the authenticated tenant',
  })
  @ApiResponse({
    status: 200,
    description: 'Return dashboard bootstrap payload.',
  })
  async getBootstrap(@Request() req: any) {
    return this.dashboardService.getBootstrap(req.tenantId, req.appUser);
  }

  @Get('stats')
  @ApiOperation({
    summary: 'Get dashboard summary stats for the authenticated tenant',
  })
  @ApiResponse({ status: 200, description: 'Return dashboard summary stats.' })
  async getStats(@Request() req: any) {
    return this.dashboardService.getStats(req.tenantId);
  }
}
