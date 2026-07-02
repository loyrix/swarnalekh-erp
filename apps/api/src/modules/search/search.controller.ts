import { Controller, Get, Query, Request } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import {
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';
import { SearchQueryDto } from './search.dto.js';
import { SearchService } from './search.service.js';

@ApiTags('Search')
@Controller('search')
@ApiBearerAuth()
@Roles(...ALL_APP_ROLES)
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  @ApiOperation({
    summary: 'Global cross-entity search (customers, inventory, invoices)',
  })
  @ApiQuery({ name: 'q', required: true, example: 'ring' })
  @ApiQuery({ name: 'limit', required: false, example: 5 })
  search(@Request() req: any, @Query() query: SearchQueryDto) {
    return this.searchService.search(req.tenantId, query);
  }
}
