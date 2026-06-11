import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsDate,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

export class UpdateDailyRateDto {
  @ApiProperty({ example: '2024-03-20T00:00:00.000Z', description: 'Date for the rate' })
  @Type(() => Date)
  @IsDate()
  rateDate: Date;

  @ApiProperty({ example: 'gold', description: 'Metal type (gold, silver)' })
  @IsString()
  @IsNotEmpty()
  metalType: string;

  @ApiProperty({ example: '22K', description: 'Karat purity (e.g., 24K, 22K, 18K)', required: false })
  @IsString()
  @IsOptional()
  @MaxLength(10)
  karat?: string;

  @ApiProperty({ example: 6650.00, description: 'Rate per gram' })
  @IsNumber()
  @IsNotEmpty()
  ratePerGram: number;

  @ApiProperty({ example: 'manual', description: 'Source of the rate', required: false })
  @IsString()
  @IsOptional()
  source?: string;
}

export class BulkUpdateDailyRateDto {
  @ApiProperty({ type: [UpdateDailyRateDto], description: 'Array of rates to update' })
  @IsArray()
  @IsNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => UpdateDailyRateDto)
  rates: UpdateDailyRateDto[];
}

export class DailyRateHistoryQueryDto {
  @ApiPropertyOptional({
    example: 15,
    description: 'Number of days of history to return',
    default: 15,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  days?: number = 15;
}
