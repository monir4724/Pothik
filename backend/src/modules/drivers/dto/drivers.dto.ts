import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class CreateDriverProfileDto {
  @ApiProperty({ example: '1990123456789' })
  @IsNotEmpty()
  @IsString()
  nidNumber: string;

  @ApiProperty({ example: 'DL-987654321' })
  @IsNotEmpty()
  @IsString()
  drivingLicenseNumber: string;
}

export class UploadDriverDocumentDto {
  @ApiProperty({ example: 'nid_front', description: 'Document type (e.g. nid_front, driving_license)' })
  @IsNotEmpty()
  @IsString()
  documentType: string;

  @ApiProperty({ example: 'https://res.cloudinary.com/demo/image/upload/v123/doc.jpg' })
  @IsNotEmpty()
  @IsString()
  documentUrl: string;
}

export class CreateVehicleDto {
  @ApiProperty({ example: 'economy', description: 'economy | premium | bike | cng' })
  @IsNotEmpty()
  @IsString()
  vehicleType: string;

  @ApiProperty({ example: 'Toyota' })
  @IsNotEmpty()
  @IsString()
  make: string;

  @ApiProperty({ example: 'Axio' })
  @IsNotEmpty()
  @IsString()
  model: string;

  @ApiProperty({ example: 2018 })
  @IsNotEmpty()
  @IsNumber()
  year: number;

  @ApiProperty({ example: 'DHAKA-METRO-GA-11-2233' })
  @IsNotEmpty()
  @IsString()
  licensePlate: string;

  @ApiProperty({ example: 'Silver' })
  @IsNotEmpty()
  @IsString()
  color: string;
}
