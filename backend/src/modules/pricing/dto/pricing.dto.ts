import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdatePricingRuleDto {
  @ApiPropertyOptional({ example: 35.0 })
  @IsOptional()
  @IsNumber()
  baseFare?: number;

  @ApiPropertyOptional({ example: 14.0 })
  @IsOptional()
  @IsNumber()
  perKmRate?: number;

  @ApiPropertyOptional({ example: 2.0 })
  @IsOptional()
  @IsNumber()
  perMinuteRate?: number;

  @ApiPropertyOptional({ example: 60.0 })
  @IsOptional()
  @IsNumber()
  minimumFare?: number;

  @ApiPropertyOptional({ example: 0.20 })
  @IsOptional()
  @IsNumber()
  commissionRate?: number;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CreatePricingRuleDto {
  @ApiProperty({ example: 'premium' })
  @IsNotEmpty()
  @IsString()
  vehicleType: string;

  @ApiProperty({ example: 50.0 })
  @IsNotEmpty()
  @IsNumber()
  baseFare: number;

  @ApiProperty({ example: 20.0 })
  @IsNotEmpty()
  @IsNumber()
  perKmRate: number;

  @ApiProperty({ example: 3.0 })
  @IsNotEmpty()
  @IsNumber()
  perMinuteRate: number;

  @ApiProperty({ example: 100.0 })
  @IsNotEmpty()
  @IsNumber()
  minimumFare: number;

  @ApiPropertyOptional({ example: 0.20 })
  @IsOptional()
  @IsNumber()
  commissionRate?: number;
}
