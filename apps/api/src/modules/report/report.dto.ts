import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class ReportQueryDto {
  @ApiPropertyOptional({ example: 'ring' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: '2026-06-01' })
  @IsOptional()
  @IsString()
  dateFrom?: string;

  @ApiPropertyOptional({ example: '2026-06-10' })
  @IsOptional()
  @IsString()
  dateTo?: string;

  @ApiPropertyOptional({ example: 'Ring' })
  @IsOptional()
  @IsString()
  categoryName?: string;

  @ApiPropertyOptional({ example: 'Main Branch' })
  @IsOptional()
  @IsString()
  branch?: string;

  @ApiPropertyOptional({ example: 'active' })
  @IsOptional()
  @IsString()
  status?: string;
}
