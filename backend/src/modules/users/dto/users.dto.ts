import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString } from 'class-validator';

export class UpdateUserProfileDto {
  @ApiPropertyOptional({ example: 'Rahim Uddin' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'rahim@example.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'https://cloudinary.com/profile.jpg' })
  @IsOptional()
  @IsString()
  profilePictureUrl?: string;
}

export class RegisterDeviceTokenDto {
  @ApiProperty({ example: 'fcm_token_sample_123456' })
  @IsString()
  fcmToken: string;

  @ApiPropertyOptional({ example: 'android' })
  @IsOptional()
  @IsString()
  deviceType?: string;
}
