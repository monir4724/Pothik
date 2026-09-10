import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CashConfirmDto } from './dto/payments.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Payments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('rides/:id/payment/cash-confirm')
  @ApiOperation({ summary: 'Driver confirms receiving cash payment from passenger' })
  async confirmCashPayment(
    @CurrentUser('id') driverId: string,
    @Param('id') rideId: string,
    @Body() dto: CashConfirmDto,
  ) {
    return this.paymentsService.confirmCashPayment(driverId, rideId, dto);
  }

  @Get('drivers/me/commission-debt')
  @ApiOperation({ summary: 'Get current driver outstanding commission debt ledger' })
  async getDriverCommissionDebt(@CurrentUser('id') driverId: string) {
    return this.paymentsService.getDriverCommissionDebt(driverId);
  }
}
