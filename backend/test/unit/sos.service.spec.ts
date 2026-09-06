import { SosService } from '../../src/modules/sos/sos.service';
import { PrismaService } from '../../src/database/prisma.service';

describe('SosService Unit Tests', () => {
  let service: SosService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      guardian: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        updateMany: jest.fn(),
      },
      ride: {
        findFirst: jest.fn(),
      },
      sosRequest: {
        create: jest.fn(),
      },
    };
    service = new SosService(prismaMock as unknown as PrismaService);
  });

  it('should trigger SOS alert and contact primary guardian', async () => {
    prismaMock.ride.findFirst.mockResolvedValue({
      id: 'ride-active-1',
      passengerId: 'passenger-1',
      passenger: { name: 'Karim' },
    });

    prismaMock.guardian.findFirst.mockResolvedValue({
      id: 'g-1',
      userId: 'passenger-1',
      name: 'Rahima',
      phone: '+8801711111111',
      isPrimary: true,
    });

    prismaMock.sosRequest.create.mockResolvedValue({
      id: 'sos-1',
      passengerId: 'passenger-1',
      rideId: 'ride-active-1',
      status: 'ACTIVE',
      smsStatus: 'DELIVERED',
    });

    const result = await service.triggerSos('passenger-1', {
      rideId: 'ride-active-1',
      latitude: 23.8103,
      longitude: 90.4125,
    });

    expect(result.sosRequest.status).toBe('ACTIVE');
    expect(result.guardianContacted).toBe('+8801711111111');
  });
});
