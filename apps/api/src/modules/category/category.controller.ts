import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Request,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';
import { CreateCategoryDto, UpdateCategoryDto } from './category.dto.js';
import { CategoryService } from './category.service.js';

@ApiTags('Categories')
@Controller('categories')
@ApiBearerAuth()
export class CategoryController {
  constructor(private readonly categoryService: CategoryService) {}

  @Get()
  @Roles(...ALL_APP_ROLES)
  @ApiOperation({
    summary: 'List categories (seeds the default master list for new shops)',
  })
  list(@Request() req: any) {
    return this.categoryService.list(req.tenantId);
  }

  @Post()
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Create a category' })
  create(@Request() req: any, @Body() dto: CreateCategoryDto) {
    return this.categoryService.create(req.tenantId, dto);
  }

  @Patch(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Update a category (prefix, threshold, active)' })
  update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateCategoryDto,
  ) {
    return this.categoryService.update(req.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Delete an empty category' })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.categoryService.remove(req.tenantId, id);
  }
}
