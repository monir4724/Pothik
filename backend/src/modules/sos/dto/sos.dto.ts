import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateGuardianDto {
  @ApiProperty({ example: 'Fatema Begum' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: '+8801800000000' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiPropertyOptional({ example: 'Mother' })
  @IsOptional()
  @IsString()
  relationship?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}

export class TriggerSosDto {
  @ApiProperty({ example: 'ride_uuid_here' })
  @IsNotEmpty()
  @IsString()
  rideId: string;

  @ApiProperty({ example: 23.8103 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ example: 90.4125 })
  @IsNumber()
  longitude: number;
}
