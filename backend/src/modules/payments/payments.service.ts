import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { PricingService } from '../pricing/pricing.service';
import { CashConfirmDto } from './dto/payments.dto';

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private pricingService: PricingService,
  ) {}

  async confirmCashPayment(
    driverId: string,
    rideId: string,
    dto?: CashConfirmDto,
  ) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
      include: { payment: true, vehicle: true },
    });

    if (!ride) {
      throw new NotFoundException('Ride not found');
    }

    // Step 1: Ride status must already be COMPLETED
    if (ride.status !== 'COMPLETED') {
      throw new BadRequestException(
        `Payment cash confirmation is only allowed for completed rides. Current status is '${ride.status}'`,
      );
    }

    // Step 2: Verify requesting driver owns the ride
    if (ride.driverId !== driverId) {
      throw new ForbiddenException('You are not authorized to confirm payment for this ride');
    }

    // Step 3: Idempotency check - reject second confirmation
    if (ride.payment) {
      throw new BadRequestException('Cash payment for this ride has already been confirmed');
    }

    // Step 4: Calculate commission using pricing rule
    const vehicleType = ride.vehicle?.vehicleType || 'economy';
    const pricingRule = await this.pricingService.getRuleByVehicleType(vehicleType);
    const commissionRate = pricingRule?.commissionRate ?? 0.20;

    const amount = dto?.amountCollected ?? ride.actualFare ?? ride.estimatedFare;
    const commissionAmount = Math.round(amount * commissionRate * 100) / 100;

    // Step 5: Transactional write of Payment and DriverCommissionDebt
    const [payment, debt] = await this.prisma.$transaction(async (tx) => {
      const p = await tx.payment.create({
        data: {
          rideId: ride.id,
          driverId: ride.driverId,
          passengerId: ride.passengerId,
          amount,
          commissionAmount,
          paymentMethod: 'CASH',
          status: 'CONFIRMED',
          confirmedAt: new Date(),
        },
      });

      const d = await tx.driverCommissionDebt.create({
        data: {
          driverId: ride.driverId,
          paymentId: p.id,
          rideId: ride.id,
          amount: commissionAmount,
          status: 'UNPAID',
        },
      });

      return [p, d];
    });

    return {
      payment,
      commissionDebt: debt,
      ride,
    };
  }

  async getDriverCommissionDebt(driverId: string) {
    const debts = await this.prisma.driverCommissionDebt.findMany({
      where: {
        driverId,
      },
      include: {
        ride: true,
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const outstandingDebt = debts
      .filter((d) => d.status === 'UNPAID')
      .reduce((acc, curr) => acc + curr.amount, 0);

    return {
      outstandingDebt: Math.round(outstandingDebt * 100) / 100,
      totalDebtsRecorded: debts.length,
      debts,
    };
  }
}
