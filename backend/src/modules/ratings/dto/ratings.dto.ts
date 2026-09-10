import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

export class SubmitRatingDto {
  @ApiProperty({ example: 5, description: 'Rating score from 1 to 5' })
  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  @Max(5)
  rating: number;

  @ApiPropertyOptional({ example: 'Great drive, smooth route' })
  @IsOptional()
  @IsString()
  comment?: string;
}
