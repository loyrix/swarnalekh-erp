import { Controller, Get, Post, Body, Query, Request } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { DailyRateService } from './daily-rate.service.js';
import {
  BulkUpdateDailyRateDto,
  DailyRateHistoryQueryDto,
} from './daily-rate.dto.js';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';

@ApiTags('Daily Rates')
@Controller('daily-rates')
@ApiBearerAuth('JWT')
@Roles(...ALL_APP_ROLES)
export class DailyRateController {
  constructor(private readonly dailyRateService: DailyRateService) {}

  @Get('latest')
  @ApiOperation({ summary: 'Get the latest daily rates (usually today)' })
  @ApiResponse({ status: 200, description: 'Return latest rates.' })
  async getLatestRates(@Request() req: any) {
    return this.dailyRateService.getLatestRates(req.tenantId);
  }

  @Get('today')
  @ApiOperation({ summary: 'Get rates for today' })
  @ApiResponse({ status: 200, description: 'Return today rates.' })
  async getTodayRates(@Request() req: any) {
    return this.dailyRateService.getTodayRates(req.tenantId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get recent daily rate history' })
  @ApiQuery({ name: 'days', required: false, example: 15 })
  @ApiResponse({
    status: 200,
    description: 'Return recent grouped rate history.',
  })
  async getHistory(
    @Request() req: any,
    @Query() query: DailyRateHistoryQueryDto,
  ) {
    return this.dailyRateService.getHistory(req.tenantId, query.days);
  }

  @Get()
  @ApiOperation({ summary: 'Get rates for a specific date' })
  @ApiQuery({
    name: 'date',
    required: true,
    example: '2024-03-20',
    description: 'YYYY-MM-DD',
  })
  @ApiResponse({
    status: 200,
    description: 'Return rates for the specified date.',
  })
  async getRatesByDate(@Request() req: any, @Query('date') dateParam: string) {
    const queryDate = dateParam ? new Date(dateParam) : new Date();
    return this.dailyRateService.getRatesByDate(req.tenantId, queryDate);
  }

  @Post('bulk')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Update or insert multiple rates at once' })
  @ApiResponse({ status: 201, description: 'Rates successfully updated.' })
  async bulkUpdate(@Request() req: any, @Body() dto: BulkUpdateDailyRateDto) {
    return this.dailyRateService.bulkUpdate(req.tenantId, req.appUser.id, dto);
  }
}
