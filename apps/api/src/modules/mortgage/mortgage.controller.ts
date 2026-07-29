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
import {
  CloseMortgageLoanDto,
  CollectMortgagePaymentDto,
  CreateMortgageLoanDto,
  MortgageDashboardQueryDto,
  ReopenMortgageLoanDto,
  TopUpMortgageLoanDto,
  UpdateMortgageLoanDto,
  UpdateMortgagePaymentDto,
} from './mortgage.dto.js';
import { MortgageService } from './mortgage.service.js';
import {
  ADMIN_ROLES,
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';

@ApiTags('Mortgage')
@Controller('mortgages')
@ApiBearerAuth()
@Roles(...ALL_APP_ROLES)
export class MortgageController {
  constructor(private readonly mortgageService: MortgageService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Mortgage dashboard summary for the tenant' })
  @ApiQuery({ name: 'period', required: false, example: '6months' })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-01-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-30' })
  async getDashboard(
    @Request() req: any,
    @Query() query: MortgageDashboardQueryDto,
  ) {
    return this.mortgageService.getDashboard(req.tenantId, query);
  }

  @Get()
  @ApiOperation({ summary: 'List mortgage loans for the authenticated tenant' })
  @ApiQuery({ name: 'status', required: false, example: 'active' })
  @ApiQuery({ name: 'search', required: false, example: 'Priya' })
  async findAll(
    @Request() req: any,
    @Query('status') status?: string,
    @Query('search') search?: string,
  ) {
    return this.mortgageService.findAll(req.tenantId, {
      status: status?.trim() || undefined,
      search: search?.trim() || undefined,
    });
  }

  @Post()
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Create a mortgage/gold loan' })
  async create(@Request() req: any, @Body() dto: CreateMortgageLoanDto) {
    return this.mortgageService.createLoan(req.tenantId, req.appUser?.id, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get full mortgage loan details' })
  async findOne(@Request() req: any, @Param('id') id: string) {
    return this.mortgageService.findOne(req.tenantId, id);
  }

  @Get(':id/ledger')
  @ApiOperation({ summary: 'Chronological transaction ledger for a loan' })
  async getLedger(@Request() req: any, @Param('id') id: string) {
    return this.mortgageService.getLedger(req.tenantId, id);
  }

  @Put(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Edit a loan (customer details, rate, notes)' })
  async updateLoan(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateMortgageLoanDto,
  ) {
    return this.mortgageService.updateLoan(req.tenantId, id, dto);
  }

  @Post(':id/payments')
  @ApiOperation({ summary: 'Collect mortgage interest or principal payment' })
  async collectPayment(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: CollectMortgagePaymentDto,
  ) {
    return this.mortgageService.collectPayment(
      req.tenantId,
      req.appUser?.id,
      id,
      dto,
    );
  }

  @Patch(':id/payments/:paymentId')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Correct a recorded mortgage payment (amount / type)',
  })
  async updatePayment(
    @Request() req: any,
    @Param('id') id: string,
    @Param('paymentId') paymentId: string,
    @Body() dto: UpdateMortgagePaymentDto,
  ) {
    return this.mortgageService.updatePayment(req.tenantId, id, paymentId, dto);
  }

  @Get(':id/payments/:paymentId/receipt')
  @ApiOperation({ summary: 'Generate a mortgage payment receipt PDF payload' })
  async getPaymentReceipt(
    @Request() req: any,
    @Param('id') id: string,
    @Param('paymentId') paymentId: string,
  ) {
    return this.mortgageService.getPaymentReceiptPdf(
      req.tenantId,
      id,
      paymentId,
    );
  }

  @Get(':id/close-preview')
  @ApiOperation({
    summary: 'Settlement figures under both top-up interest policies',
  })
  async getClosePreview(@Request() req: any, @Param('id') id: string) {
    return this.mortgageService.getClosePreview(req.tenantId, id);
  }

  @Post(':id/close')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Close a mortgage loan after settlement' })
  async closeLoan(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: CloseMortgageLoanDto,
  ) {
    return this.mortgageService.closeLoan(
      req.tenantId,
      req.appUser?.id,
      id,
      dto,
    );
  }

  @Post(':id/topups')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Add a principal top-up to an active loan' })
  async topUpLoan(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: TopUpMortgageLoanDto,
  ) {
    return this.mortgageService.topUpLoan(
      req.tenantId,
      req.appUser?.id,
      id,
      dto,
    );
  }

  @Post(':id/reopen')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({
    summary: 'Reopen a closed loan to correct Collect/Close entries',
  })
  async reopenLoan(
    @Request() req: any,
    @Param('id') id: string,
    @Body() dto: ReopenMortgageLoanDto,
  ) {
    return this.mortgageService.reopenLoan(req.tenantId, id, dto);
  }

  @Delete(':id')
  @Roles(...ADMIN_ROLES)
  @ApiOperation({ summary: 'Soft-delete a mortgage loan' })
  async remove(@Request() req: any, @Param('id') id: string) {
    return this.mortgageService.remove(req.tenantId, id);
  }
}
