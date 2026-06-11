import { Controller, Get, Param, Query, Request } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_ROLES, Roles } from '../../common/decorators/roles.decorator.js';
import { ReportQueryDto } from './report.dto.js';
import { REPORT_TYPES, ReportService } from './report.service.js';

@ApiTags('Reports')
@Controller('reports')
@ApiBearerAuth()
@Roles(...ADMIN_ROLES)
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Get('overview')
  @ApiOperation({ summary: 'PDF jewellery ERP report overview' })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-10' })
  @ApiQuery({ name: 'categoryName', required: false, example: 'Ring' })
  @ApiQuery({ name: 'branch', required: false, example: 'Main Branch' })
  @ApiQuery({ name: 'status', required: false, example: 'active' })
  getOverview(@Request() req: any, @Query() query: ReportQueryDto) {
    return this.reportService.getOverview(req.tenantId, query);
  }

  @Get('export/:type')
  @ApiOperation({ summary: 'Export a PDF jewellery ERP report' })
  @ApiParam({ name: 'type', enum: REPORT_TYPES })
  getExport(
    @Request() req: any,
    @Param('type') type: string,
    @Query() query: ReportQueryDto,
  ) {
    return this.reportService.getExport(req.tenantId, type, query);
  }
}
