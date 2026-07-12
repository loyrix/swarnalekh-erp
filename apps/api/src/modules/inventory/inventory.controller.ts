import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  Query,
  Request,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiQuery,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { InventoryService } from './inventory.service';
import {
  CreateInventoryDto,
  ImportInventoryDto,
  InventoryStatsQueryDto,
  UpdateInventoryDto,
} from './inventory.dto';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator';

@ApiTags('Inventory')
@Controller('inventory')
@ApiBearerAuth()
@Roles(...ALL_APP_ROLES)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get('overview')
  @ApiOperation({
    summary:
      'Inventory overview with items and stats for the authenticated tenant',
  })
  @ApiQuery({ name: 'status', required: false, example: 'in_stock' })
  @ApiQuery({ name: 'metalType', required: false, example: 'gold' })
  @ApiQuery({ name: 'search', required: false, example: 'Ring' })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiQuery({ name: 'categoryName', required: false, example: 'Ring' })
  @ApiQuery({ name: 'location', required: false, example: 'Main Branch' })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-10' })
  async getOverview(
    @Request() req: any,
    @Query('status') status?: string,
    @Query('metalType') metalType?: string,
    @Query('search') search?: string,
    @Query('categoryId') categoryId?: string,
    @Query('categoryName') categoryName?: string,
    @Query('location') location?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.inventoryService.getOverview(req.tenantId, {
      status,
      metalType,
      search,
      categoryId,
      categoryName,
      location,
      dateFrom,
      dateTo,
    });
  }

  @Get()
  @ApiOperation({
    summary: 'List inventory items for the authenticated tenant',
  })
  @ApiQuery({ name: 'status', required: false, example: 'in_stock' })
  @ApiQuery({ name: 'metalType', required: false, example: 'gold' })
  @ApiQuery({ name: 'search', required: false, example: 'Ring' })
  @ApiQuery({ name: 'categoryId', required: false })
  @ApiQuery({ name: 'categoryName', required: false, example: 'Ring' })
  @ApiQuery({ name: 'location', required: false, example: 'Main Branch' })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-10' })
  async findAll(
    @Request() req: any,
    @Query('status') status?: string,
    @Query('metalType') metalType?: string,
    @Query('search') search?: string,
    @Query('categoryId') categoryId?: string,
    @Query('categoryName') categoryName?: string,
    @Query('location') location?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.inventoryService.findAll(req.tenantId, {
      status,
      metalType,
      search,
      categoryId,
      categoryName,
      location,
      dateFrom,
      dateTo,
    });
  }

  @Get('stats')
  @ApiOperation({
    summary: 'Inventory statistics (stock count, weight by metal)',
  })
  @ApiQuery({ name: 'period', required: false, example: '6months' })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-01-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-30' })
  async getStats(@Request() req: any, @Query() query: InventoryStatsQueryDto) {
    return this.inventoryService.getStats(req.tenantId, query);
  }

  @Get('sold-products')
  @ApiOperation({
    summary: 'Sold products with invoice and payment details',
  })
  @ApiQuery({ name: 'search', required: false, example: 'SLK-2026-0001' })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-10' })
  async getSoldProducts(
    @Request() req: any,
    @Query('search') search?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.inventoryService.getSoldProducts(req.tenantId, {
      search,
      dateFrom,
      dateTo,
    });
  }

  @Post('ocr-preview')
  @Roles(...ADMIN_ROLES)
  @UseInterceptors(FileInterceptor('receipt'))
  @ApiOperation({
    summary: 'Parse a HUID receipt image into draft inventory rows',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        receipt: {
          type: 'string',
          format: 'binary',
        },
      },
      required: ['receipt'],
    },
  })
  async previewReceiptOcr(@UploadedFile() file: Express.Multer.File) {
    return this.inventoryService.previewReceiptOcr(file);
  }

  @Post('import')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Create reviewed inventory rows from an import preview',
  })
  async importItems(@Request() req: any, @Body() dto: ImportInventoryDto) {
    return this.inventoryService.importItems(req.tenantId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get inventory item by ID' })
  async findOne(@Request() req: any, @Param('id') id: string) {
    return this.inventoryService.findOne(req.tenantId, id);
  }

  @Post()
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Create inventory item for the authenticated tenant',
  })
  async create(@Request() req: any, @Body() dto: CreateInventoryDto) {
    return this.inventoryService.create(req.tenantId, dto);
  }

  @Put(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Update inventory item for the authenticated tenant',
  })
  async update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateInventoryDto,
  ) {
    return this.inventoryService.update(req.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Soft-delete inventory item for the authenticated tenant',
  })
  async remove(@Request() req: any, @Param('id') id: string) {
    return this.inventoryService.remove(req.tenantId, id);
  }
}
