import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';

const MANAGED_ROLES = ['admin', 'staff'] as const;

export class CreateManagedUserDto {
  @ApiProperty({ example: 'Asha Sharma' })
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  name: string;

  @ApiProperty({ example: 'asha@shop.com' })
  @IsEmail()
  @MaxLength(200)
  email: string;

  @ApiPropertyOptional({ example: '+919999000111' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string | null;

  @ApiProperty({ example: 'staff', enum: MANAGED_ROLES })
  @IsIn(MANAGED_ROLES)
  role: (typeof MANAGED_ROLES)[number];
}

export class UpdateManagedUserDto {
  @ApiPropertyOptional({ example: 'Asha Sharma' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(150)
  name?: string;

  @ApiPropertyOptional({ example: 'asha@shop.com' })
  @IsOptional()
  @IsEmail()
  @MaxLength(200)
  email?: string | null;

  @ApiPropertyOptional({ example: '+919999000111' })
  @IsOptional()
  @IsString()
  @MaxLength(15)
  phone?: string | null;

  @ApiPropertyOptional({ example: 'admin', enum: MANAGED_ROLES })
  @IsOptional()
  @IsIn(MANAGED_ROLES)
  role?: (typeof MANAGED_ROLES)[number];

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class ManagedUserQueryDto {
  @ApiPropertyOptional({ example: 'asha' })
  @IsOptional()
  @IsString()
  search?: string;
}
