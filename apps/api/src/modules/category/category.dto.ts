import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const PREFIX_PATTERN = /^[A-Z]{2,6}$/;
const PREFIX_MESSAGE = 'prefix must be 2-6 uppercase letters (e.g. RG)';

export class CreateCategoryDto {
  @ApiProperty({ example: 'Ring' })
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @ApiPropertyOptional({ example: 'RG', description: '2-6 uppercase letters' })
  @IsOptional()
  @IsString()
  @Matches(PREFIX_PATTERN, { message: PREFIX_MESSAGE })
  prefix?: string;

  @ApiPropertyOptional({ example: 2, minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  minStockThreshold?: number;
}

export class UpdateCategoryDto {
  @ApiPropertyOptional({ example: 'Ring' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ example: 'RG', description: '2-6 uppercase letters' })
  @IsOptional()
  @IsString()
  @Matches(PREFIX_PATTERN, { message: PREFIX_MESSAGE })
  prefix?: string;

  @ApiPropertyOptional({ example: 2, minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  minStockThreshold?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
