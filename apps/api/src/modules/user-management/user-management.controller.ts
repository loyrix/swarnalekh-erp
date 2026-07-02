import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  Request,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from '@nestjs/swagger';
import { ADMIN_ROLES, Roles } from '../../common/decorators/roles.decorator.js';
import {
  CreateManagedUserDto,
  ManagedUserQueryDto,
  SetUserPasswordDto,
  UpdateManagedUserDto,
} from './user-management.dto.js';
import { UserManagementService } from './user-management.service.js';

@ApiTags('User Management')
@Controller('users')
@ApiBearerAuth()
@Roles(...ADMIN_ROLES)
export class UserManagementController {
  constructor(private readonly userManagementService: UserManagementService) {}

  @Get()
  @ApiOperation({ summary: 'List shop users for Admin user management' })
  @ApiQuery({ name: 'search', required: false, example: 'asha' })
  async findAll(@Request() req: any, @Query() query: ManagedUserQueryDto) {
    return this.userManagementService.findAll(req.tenantId, query);
  }

  @Post()
  @ApiOperation({ summary: 'Create a staff or admin user for this shop' })
  async create(@Request() req: any, @Body() dto: CreateManagedUserDto) {
    return this.userManagementService.create(req.tenantId, dto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update a shop user' })
  async update(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateManagedUserDto,
  ) {
    return this.userManagementService.update(
      req.tenantId,
      req.appUser.id,
      id,
      dto,
    );
  }

  @Patch(':id/password')
  @ApiOperation({ summary: "Set or reset a shop user's login password" })
  async setPassword(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: SetUserPasswordDto,
  ) {
    return this.userManagementService.setPassword(
      req.tenantId,
      id,
      dto.password,
    );
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deactivate a shop user' })
  async deactivate(@Request() req: any, @Param('id') id: string) {
    return this.userManagementService.deactivate(
      req.tenantId,
      req.appUser.id,
      id,
    );
  }
}
