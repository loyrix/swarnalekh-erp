import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsOptional,
  IsEmail,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateCustomerDto {
  @ApiProperty({ example: 'Priya Singh' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  name: string;

  @ApiPropertyOptional({ example: '+919111222333' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string;

  @ApiPropertyOptional({ example: '+919111222334' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  altPhone?: string;

  @ApiPropertyOptional({ example: 'priya@email.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: '45 Park Avenue, Mumbai' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @ApiPropertyOptional({ example: '400001' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  pincode?: string;

  @ApiPropertyOptional({ example: '22K' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  preferredKarat?: string;

  @ApiPropertyOptional({ example: 'Regular customer, prefers traditional designs' })
  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateCustomerDto {
  @ApiPropertyOptional({ example: 'Priya Singh' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  name?: string;

  @ApiPropertyOptional({ example: '+919111222333' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string;

  @ApiPropertyOptional({ example: 'priya@email.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: '45 Park Avenue' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Mumbai' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @ApiPropertyOptional({ example: '400002' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  pincode?: string;

  @ApiPropertyOptional({ example: '24K' })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  preferredKarat?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;
}
