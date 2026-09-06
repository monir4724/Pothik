import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';
import { Transform } from 'class-transformer';

export class EstimateRideDto {
  @ApiProperty({ example: 23.8103 })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  pickupLat: number;

  @ApiProperty({ example: 90.4125 })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  pickupLng: number;

  @ApiProperty({ example: 23.7940 })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  dropoffLat: number;

  @ApiProperty({ example: 90.4043 })
  @Transform(({ value }) => parseFloat(value))
  @IsNumber()
  dropoffLng: number;

  @ApiPropertyOptional({ example: 'economy' })
  @IsOptional()
  @IsString()
  vehicleType?: string;
}

export class CreateRideDto {
  @ApiProperty({ example: 23.8103 })
  @IsNumber()
  pickupLat: number;

  @ApiProperty({ example: 90.4125 })
  @IsNumber()
  pickupLng: number;

  @ApiProperty({ example: 'Gulshan 2, Dhaka' })
  @IsNotEmpty()
  @IsString()
  pickupAddress: string;

  @ApiProperty({ example: 23.7940 })
  @IsNumber()
  dropoffLat: number;

  @ApiProperty({ example: 90.4043 })
  @IsNumber()
  dropoffLng: number;

  @ApiProperty({ example: 'Banani, Dhaka' })
  @IsNotEmpty()
  @IsString()
  dropoffAddress: string;

  @ApiPropertyOptional({ example: 'economy' })
  @IsOptional()
  @IsString()
  vehicleType?: string;
}

export class CancelRideDto {
  @ApiPropertyOptional({ example: 'Changed my mind' })
  @IsOptional()
  @IsString()
  reason?: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '1234' })
  @IsNotEmpty()
  @IsString()
  otp: string;
}

export class DeclineRideDto {
  @ApiPropertyOptional({ example: 'Too far away' })
  @IsOptional()
  @IsString()
  reason?: string;
}
