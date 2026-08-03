import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class AddInvoicePaymentDto {
  @ApiProperty({ description: 'Payment amount to record', example: 5000 })
  @IsNumber()
  @IsPositive()
  amount: number;

  @ApiPropertyOptional({
    description: 'Payment mode (cash, upi, card, …)',
    example: 'upi',
  })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  paymentMode?: string;

  @ApiPropertyOptional({ description: 'Reference / transaction number' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  referenceNumber?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class CreateInvoiceItemDto {
  @ApiPropertyOptional({
    description:
      'Inventory Item ID. Omit for an on-demand (made-to-order) line, which ' +
      'carries its own weight/karat instead of drawing from stock.',
  })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  inventoryItemId?: string;

  @ApiProperty({
    description: 'Quantity to sell from the selected inventory row',
    required: false,
    default: 1,
  })
  @IsNumber()
  @IsOptional()
  quantity?: number;

  @ApiProperty({
    description: 'Override making charges for this specific item',
    required: false,
  })
  @IsNumber()
  @IsOptional()
  makingCharges?: number;

  // ---- On-demand (made-to-order) line -------------------------------------
  // Used only when `inventoryItemId` is absent. The line is priced from the
  // weight below at the tenant's daily rate for the metal/karat, and no stock
  // is reserved or decremented.

  @ApiPropertyOptional({
    description: 'On-demand line: what is being made (e.g. "Custom ring")',
  })
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  @MaxLength(200)
  itemName?: string;

  @ApiPropertyOptional({
    description: 'On-demand line: metal type — gold or silver',
    example: 'gold',
  })
  @IsString()
  @IsOptional()
  @MaxLength(20)
  metalType?: string;

  @ApiPropertyOptional({
    description: 'On-demand line: purity / karat, e.g. 22K',
    example: '22K',
  })
  @IsString()
  @IsOptional()
  @MaxLength(10)
  karat?: string;

  @ApiPropertyOptional({
    description: 'On-demand line: metal weight in grams',
    example: 8.5,
  })
  @IsNumber()
  @IsPositive()
  @IsOptional()
  netWeight?: number;
}

export class CreateInvoiceDto {
  @ApiProperty({ description: 'Customer ID', required: false })
  @IsString()
  @IsOptional()
  customerId?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  customerName?: string;
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  customerPhone?: string;

  @ApiProperty({ required: false, description: 'Customer billing address' })
  @IsString()
  @IsOptional()
  customerAddress?: string;

  @ApiProperty({
    required: false,
    description:
      'Gold rate (per gram) typed on the bill; applies to all rate-priced ' +
      'items in this bill. Items with an explicit selling price keep it.',
  })
  @IsNumber()
  @IsOptional()
  ratePerGramOverride?: number;

  @ApiProperty({
    required: false,
    description: 'Making charge (per gram of gross weight) typed on the bill.',
  })
  @IsNumber()
  @IsOptional()
  makingPerGramOverride?: number;

  @ApiProperty({
    required: false,
    description: 'Total GST % typed on the bill (split evenly CGST/SGST).',
  })
  @IsNumber()
  @IsOptional()
  gstPercentOverride?: number;

  @ApiProperty({ type: [CreateInvoiceItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateInvoiceItemDto)
  items: CreateInvoiceItemDto[];

  @ApiProperty({ description: 'Discount amount on total invoice' })
  @IsNumber()
  @IsOptional()
  discountAmount?: number;

  @ApiProperty({
    description: 'Old gold weight received in grams',
    required: false,
  })
  @IsNumber()
  @IsOptional()
  oldGoldWeight?: number;

  @ApiProperty({ description: 'Old gold karat', required: false })
  @IsString()
  @IsOptional()
  oldGoldKarat?: string;

  @ApiProperty({
    description: 'Old gold rate applied (per g)',
    required: false,
  })
  @IsNumber()
  @IsOptional()
  oldGoldRate?: number;

  @ApiPropertyOptional({
    description:
      'Old gold exchange value in rupees, agreed at the counter. When present ' +
      'this is used as-is and the weight x rate calculation is skipped. Like ' +
      'a discount, it reduces the taxable amount before GST.',
    example: 12000,
  })
  @IsNumber()
  @Min(0)
  @IsOptional()
  oldGoldValue?: number;

  @ApiProperty({ description: 'Amount paid immediately' })
  @IsNumber()
  @IsOptional()
  amountPaid?: number;

  @ApiProperty({
    description: 'Payment Mode (cash, upi, card)',
    required: false,
  })
  @IsString()
  @IsOptional()
  paymentMode?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiProperty({
    description:
      'Client-generated key to make invoice creation idempotent (safe retries)',
    required: false,
  })
  @IsString()
  @IsOptional()
  idempotencyKey?: string;
}
