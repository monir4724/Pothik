import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional } from 'class-validator';

export class CashConfirmDto {
  @ApiPropertyOptional({ example: 120.0, description: 'Optional collected cash amount override' })
  @IsOptional()
  @IsNumber()
  amountCollected?: number;
}
