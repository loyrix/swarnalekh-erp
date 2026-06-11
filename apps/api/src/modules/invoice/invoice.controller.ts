import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  Request,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { InvoiceService } from './invoice.service.js';
import { CreateInvoiceDto } from './invoice.dto.js';
import {
  ALL_APP_ROLES,
  Roles,
} from '../../common/decorators/roles.decorator.js';

@ApiTags('Invoices')
@Controller('invoices')
@ApiBearerAuth('JWT')
@Roles(...ALL_APP_ROLES)
export class InvoiceController {
  constructor(private readonly invoiceService: InvoiceService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new invoice and process items' })
  @ApiResponse({ status: 201, description: 'Invoice successfully created.' })
  async createInvoice(@Request() req: any, @Body() dto: CreateInvoiceDto) {
    return this.invoiceService.createInvoice(req.tenantId, req.appUser.id, dto);
  }

  @Get('dashboard')
  @ApiOperation({ summary: 'Get billing dashboard metrics' })
  @ApiResponse({
    status: 200,
    description: 'Return billing dashboard metrics.',
  })
  async getDashboard(@Request() req: any) {
    return this.invoiceService.getDashboard(req.tenantId);
  }

  @Get()
  @ApiOperation({ summary: 'Get all invoices' })
  @ApiQuery({
    name: 'search',
    required: false,
    description: 'Search by invoice number, customer name, or mobile number',
  })
  @ApiQuery({ name: 'dateFrom', required: false, example: '2026-06-01' })
  @ApiQuery({ name: 'dateTo', required: false, example: '2026-06-10' })
  @ApiResponse({ status: 200, description: 'Return list of invoices.' })
  async findAll(
    @Request() req: any,
    @Query('search') search?: string,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
  ) {
    return this.invoiceService.findAll(req.tenantId, {
      search,
      dateFrom,
      dateTo,
    });
  }

  @Get(':id/print')
  @ApiOperation({ summary: 'Get printable invoice data with GST breakdown' })
  @ApiResponse({ status: 200, description: 'Return printable invoice data.' })
  async getPrintableInvoice(@Request() req: any, @Param('id') id: string) {
    return this.invoiceService.getPrintableInvoice(req.tenantId, id);
  }

  @Get(':id/pdf')
  @ApiOperation({ summary: 'Generate a protected PDF payload for an invoice' })
  @ApiResponse({ status: 200, description: 'Return PDF as base64 payload.' })
  async getInvoicePdf(@Request() req: any, @Param('id') id: string) {
    return this.invoiceService.getInvoicePdf(req.tenantId, id);
  }

  @Get(':id/share')
  @ApiOperation({ summary: 'Generate WhatsApp share payload for an invoice' })
  @ApiResponse({ status: 200, description: 'Return WhatsApp share payload.' })
  async getInvoiceShare(@Request() req: any, @Param('id') id: string) {
    return this.invoiceService.getInvoiceShare(req.tenantId, id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get invoice details by ID' })
  @ApiResponse({ status: 200, description: 'Return full invoice details.' })
  async findOne(@Request() req: any, @Param('id') id: string) {
    return this.invoiceService.findOne(req.tenantId, id);
  }
}
