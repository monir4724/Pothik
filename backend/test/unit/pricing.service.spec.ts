import { PricingService } from '../../src/modules/pricing/pricing.service';
import { PrismaService } from '../../src/database/prisma.service';

describe('PricingService Unit Tests', () => {
  let service: PricingService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      pricingRule: {
        findUnique: jest.fn(),
      },
    };
    service = new PricingService(prismaMock as unknown as PrismaService);
  });

  it('should calculate fare correctly for economy vehicle type', async () => {
    prismaMock.pricingRule.findUnique.mockResolvedValue({
      vehicleType: 'economy',
      baseFare: 30.0,
      perKmRate: 12.0,
      perMinuteRate: 1.5,
      minimumFare: 50.0,
      commissionRate: 0.2,
    });

    // 5 km, 10 minutes -> 30 + (5*12) + (10*1.5) = 30 + 60 + 15 = 105
    const result = await service.calculateFare('economy', 5, 10);
    expect(result.estimatedFare).toBe(105.0);
  });

  it('should enforce minimum fare if calculated fare is below threshold', async () => {
    prismaMock.pricingRule.findUnique.mockResolvedValue({
      vehicleType: 'economy',
      baseFare: 30.0,
      perKmRate: 12.0,
      perMinuteRate: 1.5,
      minimumFare: 50.0,
      commissionRate: 0.2,
    });

    // 0.5 km, 2 minutes -> 30 + 6 + 3 = 39 -> should return min fare 50
    const result = await service.calculateFare('economy', 0.5, 2);
    expect(result.estimatedFare).toBe(50.0);
  });
});
