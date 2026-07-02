import { Controller, Get, Param, Query, Request } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_ROLES, Roles } from '../../common/decorators/roles.decorator.js';
import { ExportQueryDto } from './export.dto.js';
import { EXPORT_TYPES, ExportService } from './export.service.js';

@ApiTags('Export')
@Controller('export')
@ApiBearerAuth()
@Roles(...ADMIN_ROLES)
export class ExportController {
  constructor(private readonly exportService: ExportService) {}

  @Get(':type')
  @ApiOperation({ summary: 'Export tenant data as a CSV payload' })
  @ApiParam({ name: 'type', enum: EXPORT_TYPES })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-30' })
  @ApiQuery({ name: 'status', required: false, example: 'in_stock' })
  getExport(
    @Request() req: any,
    @Param('type') type: string,
    @Query() query: ExportQueryDto,
  ) {
    return this.exportService.export(req.tenantId, type, query);
  }
}
