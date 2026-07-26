import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDate,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class MortgageDashboardQueryDto {
  @ApiPropertyOptional({
    description: 'Collections window',
    enum: ['today', 'month', '3months', '6months', '12months', 'all', 'custom'],
  })
  @IsOptional()
  @IsString()
  period?: string;

  @ApiPropertyOptional({ example: '2026-01-01' })
  @IsOptional()
  @IsString()
  dateFrom?: string;

  @ApiPropertyOptional({ example: '2026-06-30' })
  @IsOptional()
  @IsString()
  dateTo?: string;
}

export class CreateMortgageOrnamentDto {
  @ApiProperty({ example: 'Bangles' })
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  ornamentType: string;

  @ApiPropertyOptional({ example: '22K' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  purity?: string;

  @ApiProperty({ example: 42.75 })
  @IsNumber()
  @Min(0.001)
  grossWeight: number;

  @ApiProperty({ example: 40.5 })
  @IsNumber()
  @Min(0.001)
  netWeight: number;

  @ApiPropertyOptional({ example: 245000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  estimatedValue?: number;

  @ApiPropertyOptional({ example: 'Two plain gold bangles' })
  @IsOptional()
  @IsString()
  description?: string;
}

export class CreateMortgageLoanDto {
  @ApiPropertyOptional({ description: 'Existing customer ID' })
  @IsOptional()
  @IsUUID()
  customerId?: string;

  @ApiPropertyOptional({ example: 'Priya Singh' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  customerName?: string;

  @ApiPropertyOptional({ example: '+919111222333' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  customerPhone?: string;

  @ApiPropertyOptional({ example: '45 Park Avenue, Mumbai' })
  @IsOptional()
  @IsString()
  customerAddress?: string;

  @ApiPropertyOptional({ example: '1234 5678 9012' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  aadhaarNumber?: string;

  @ApiPropertyOptional({ example: 'ABCDE1234F' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  panNumber?: string;

  @ApiPropertyOptional({ description: 'Photo ID image URL or data URI' })
  @IsOptional()
  @IsString()
  photoIdUrl?: string;

  @ApiPropertyOptional({ description: 'Customer photo URL or data URI' })
  @IsOptional()
  @IsString()
  customerPhotoUrl?: string;

  @ApiProperty({ example: 100000 })
  @IsNumber()
  @Min(1)
  principalAmount: number;

  @ApiProperty({ example: 2 })
  @IsNumber()
  @Min(0)
  interestRateMonthly: number;

  @ApiPropertyOptional({ example: '2026-06-10T00:00:00.000Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  loanDate?: Date;

  @ApiPropertyOptional({ example: '2026-07-10T00:00:00.000Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  dueDate?: Date;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiProperty({ type: [CreateMortgageOrnamentDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateMortgageOrnamentDto)
  ornaments: CreateMortgageOrnamentDto[];
}

/** Correct a recorded payment (wrong amount / wrong type). */
export class UpdateMortgagePaymentDto {
  @ApiPropertyOptional({ example: 2000 })
  @IsOptional()
  @IsNumber()
  @Min(1)
  amount?: number;

  @ApiPropertyOptional({ example: 'interest', enum: ['interest', 'principal'] })
  @IsOptional()
  @IsIn(['interest', 'principal'])
  paymentType?: 'interest' | 'principal';

  @ApiPropertyOptional({ example: 'Corrected amount' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

export class CollectMortgagePaymentDto {
  @ApiProperty({ example: 2000 })
  @IsNumber()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({ example: 'interest', enum: ['interest', 'principal'] })
  @IsOptional()
  @IsIn(['interest', 'principal'])
  paymentType?: 'interest' | 'principal';

  @ApiPropertyOptional({ example: 'cash' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  paymentMode?: string;

  @ApiPropertyOptional({ example: '2026-06-10T00:00:00.000Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  paymentDate?: Date;

  @ApiPropertyOptional({ example: 'UPI123456' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  referenceNumber?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}

export class CloseMortgageLoanDto {
  @ApiProperty({ example: 93500 })
  @IsNumber()
  @Min(0)
  amountPaid: number;

  @ApiPropertyOptional({ example: 'cash' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  paymentMode?: string;

  @ApiPropertyOptional({ example: '2026-06-10T00:00:00.000Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  closureDate?: Date;

  @ApiPropertyOptional({ example: 'Closed after full settlement' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class ReopenMortgageLoanDto {
  @ApiPropertyOptional({ example: 'Reopened to correct a wrong collection' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class TopUpMortgageLoanDto {
  @ApiProperty({ example: 25000, description: 'Principal added to the loan' })
  @IsNumber()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({ example: '2026-07-26T00:00:00.000Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  topupDate?: Date;

  @ApiPropertyOptional({ example: 'Customer requested an additional advance' })
  @IsOptional()
  @IsString()
  notes?: string;
}
