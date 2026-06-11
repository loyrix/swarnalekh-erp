import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEmail,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterTenantDto {
  @ApiProperty({ example: 'Shree Krishna Jewellers' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  shopName: string;

  @ApiProperty({ example: 'Rajesh Sharma' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  ownerName: string;

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @ApiPropertyOptional({ example: 'Maharashtra' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  state?: string;

  @ApiPropertyOptional({ example: '27AAAAA0000Z1Z5' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  gstin?: string;
}

export class UpdateTenantDto {
  @ApiPropertyOptional({ example: 'Shree Krishna Jewellers' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  shopName?: string;

  @ApiPropertyOptional({ example: 'Rajesh Sharma' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  ownerName?: string;

  @ApiPropertyOptional({ example: '45 Jewellers Market' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @ApiPropertyOptional({ example: 'Maharashtra' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  state?: string;

  @ApiPropertyOptional({ example: '400002' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  pincode?: string;

  @ApiPropertyOptional({ example: '27AAAAA0000Z1Z5' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  gstin?: string;

  @ApiPropertyOptional({ example: 'AAAAA0000Z' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  pan?: string;

  @ApiPropertyOptional({ example: 'owner@shreekrishna.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: '+919876543210' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string;
}
