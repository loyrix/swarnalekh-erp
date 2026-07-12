import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class InventoryStatsQueryDto {
  @ApiPropertyOptional({
    description: 'Window for the "sold" count',
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

export class CreateInventoryDto {
  @ApiProperty({ example: 'Lakshmi Haar' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  itemName: string;

  @ApiProperty({ example: 'gold' })
  @IsString()
  @MaxLength(20)
  metalType: string;

  @ApiPropertyOptional({ example: '22K' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  karat?: string;

  @ApiPropertyOptional({ example: 'unique' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  stockType?: string;

  @ApiPropertyOptional({ example: 12 })
  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;

  @ApiProperty({ example: 45.5 })
  @IsNumber()
  grossWeight: number;

  @ApiProperty({ example: 43.2 })
  @IsNumber()
  netWeight: number;

  @ApiPropertyOptional({ example: 'GN-001' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  tagNumber?: string;

  @ApiPropertyOptional({ example: 'DES-2245' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  barcode?: string;

  @ApiPropertyOptional({ example: 'Ring' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  categoryName?: string;

  @ApiPropertyOptional({ example: '9c457a77-7673-4d7b-8e8f-87fd070b2219' })
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional({ example: 'ABCD1234' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  huid?: string;

  @ApiPropertyOptional({ example: 'BIS123456' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  hallmarkNumber?: string;

  @ApiPropertyOptional({ example: 91.667 })
  @IsOptional()
  @IsNumber()
  purity?: number;

  @ApiPropertyOptional({ example: 450 })
  @IsOptional()
  @IsNumber()
  makingChargesPerGram?: number;

  @ApiPropertyOptional({ example: 5500 })
  @IsOptional()
  @IsNumber()
  makingChargesFixed?: number;

  @ApiPropertyOptional({ example: 8.5 })
  @IsOptional()
  @IsNumber()
  makingChargesPercent?: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsNumber()
  wastagePercent?: number;

  @ApiPropertyOptional({ example: 0.35 })
  @IsOptional()
  @IsNumber()
  stoneWeight?: number;

  @ApiPropertyOptional({ example: 12500 })
  @IsOptional()
  @IsNumber()
  stoneValue?: number;

  @ApiPropertyOptional({ example: 5850 })
  @IsOptional()
  @IsNumber()
  purchaseRate?: number;

  @ApiPropertyOptional({ example: 58100 })
  @IsOptional()
  @IsNumber()
  sellingPrice?: number;

  @ApiPropertyOptional({ example: '2026-06-10' })
  @IsOptional()
  @IsDateString()
  purchaseDate?: string;

  @ApiPropertyOptional({ example: ['https://example.com/ring.jpg'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @ApiPropertyOptional({ example: 'in_stock' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  status?: string;

  @ApiPropertyOptional({ example: 'Display Case A' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional({ example: 'ocr' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  source?: string;
}

export class UpdateInventoryDto extends CreateInventoryDto {}

export class ImportInventoryRowDto extends CreateInventoryDto {}

export class ImportInventoryDto {
  @ApiProperty({ type: [ImportInventoryRowDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ImportInventoryRowDto)
  rows: ImportInventoryRowDto[];
}
