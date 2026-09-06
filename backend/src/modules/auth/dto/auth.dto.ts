import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsPhoneNumber, IsString } from 'class-validator';

export class RequestOtpDto {
  @ApiProperty({ example: '+8801700000000', description: 'User phone number in E.164 format' })
  @IsNotEmpty()
  @IsString()
  phone: string;
}

export class VerifyOtpDto {
  @ApiProperty({ example: '+8801700000000' })
  @IsNotEmpty()
  @IsString()
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsNotEmpty()
  @IsString()
  code: string;
}

export class RefreshTokenDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...' })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}
