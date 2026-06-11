import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';

export class CreateInvoiceItemDto {
  @ApiProperty({ description: 'Inventory Item ID' })
  @IsString()
  @IsNotEmpty()
  inventoryItemId: string;

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
}
