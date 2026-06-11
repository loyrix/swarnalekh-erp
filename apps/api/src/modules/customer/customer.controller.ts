import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { CustomerService } from './customer.service';
import { CreateCustomerDto, UpdateCustomerDto } from './customer.dto';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator';

@ApiTags('Customers')
@Controller('customers')
@ApiBearerAuth()
@Roles(...ALL_APP_ROLES)
export class CustomerController {
  constructor(private readonly customerService: CustomerService) {}

  @Get()
  @ApiOperation({ summary: 'List customers for the authenticated tenant' })
  @ApiQuery({ name: 'limit', required: false, example: 5 })
  @ApiQuery({ name: 'search', required: false, example: 'priya' })
  async findAll(
    @Request() req: any,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    return this.customerService.findAll(req.tenantId, {
      limit: limit ? Number(limit) : undefined,
      search: search?.trim() || undefined,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a customer by ID' })
  async findOne(@Request() req: any, @Param('id') id: string) {
    return this.customerService.findOne(req.tenantId, id);
  }

  @Post()
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Create a new customer' })
  async create(@Request() req: any, @Body() dto: CreateCustomerDto) {
    return this.customerService.create(req.tenantId, dto);
  }

  @Put(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Update a customer' })
  async update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateCustomerDto,
  ) {
    return this.customerService.update(req.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Soft-delete a customer' })
  async remove(@Request() req: any, @Param('id') id: string) {
    return this.customerService.remove(req.tenantId, id);
  }
}
