import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'Shree Krishna Jewellers' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  shopName: string;

  @ApiProperty({ example: 'Rajesh Sharma' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  ownerName: string;

  @ApiProperty({ example: 'owner@shop.com' })
  @IsEmail()
  @MaxLength(200)
  email: string;

  @ApiProperty({ example: 'a-strong-password', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password: string;

  @ApiPropertyOptional({ example: '+919999000111' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string;

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

export class LoginDto {
  @ApiProperty({ example: 'owner@shop.com' })
  @IsEmail()
  @MaxLength(200)
  email: string;

  @ApiProperty({ example: 'a-strong-password' })
  @IsString()
  @MinLength(1)
  @MaxLength(72)
  password: string;
}
