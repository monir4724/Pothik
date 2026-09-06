import { PaymentsService } from '../../src/modules/payments/payments.service';
import { PrismaService } from '../../src/database/prisma.service';
import { PricingService } from '../../src/modules/pricing/pricing.service';
import { BadRequestException } from '@nestjs/common';

describe('PaymentsService Unit Tests', () => {
  let service: PaymentsService;
  let prismaMock: any;
  let pricingServiceMock: any;

  beforeEach(() => {
    prismaMock = {
      ride: {
        findUnique: jest.fn(),
      },
      $transaction: jest.fn(),
    };
    pricingServiceMock = {
      getRuleByVehicleType: jest.fn().mockResolvedValue({ commissionRate: 0.20 }),
    };
    service = new PaymentsService(
      prismaMock as unknown as PrismaService,
      pricingServiceMock as unknown as PricingService,
    );
  });

  it('should reject cash confirmation if ride is already confirmed (idempotency)', async () => {
    prismaMock.ride.findUnique.mockResolvedValue({
      id: 'ride-1',
      status: 'COMPLETED',
      driverId: 'driver-user-1',
      passengerId: 'passenger-user-1',
      actualFare: 100.0,
      payment: { id: 'payment-1' }, // Payment already exists!
    });

    await expect(
      service.confirmCashPayment('driver-user-1', 'ride-1'),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject confirmation if ride status is not completed', async () => {
    prismaMock.ride.findUnique.mockResolvedValue({
      id: 'ride-2',
      status: 'IN_PROGRESS',
      driverId: 'driver-user-1',
      payment: null,
    });

    await expect(
      service.confirmCashPayment('driver-user-1', 'ride-2'),
    ).rejects.toThrow(BadRequestException);
  });
});
