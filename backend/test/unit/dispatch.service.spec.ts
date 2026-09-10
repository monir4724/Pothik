import { DispatchService } from '../../src/modules/dispatch/dispatch.service';
import { PrismaService } from '../../src/database/prisma.service';
import { RidesService } from '../../src/modules/rides/rides.service';

describe('DispatchService Unit Tests', () => {
  let service: DispatchService;
  let prismaMock: any;
  let ridesServiceMock: any;

  beforeEach(() => {
    prismaMock = {
      driverLocation: {
        findMany: jest.fn(),
      },
    };
    ridesServiceMock = {
      calculateHaversineDistance: jest.fn((lat1, lon1, lat2, lon2) => 2.0), // fixed 2km
      getRideById: jest.fn(),
    };
    service = new DispatchService(
      prismaMock as unknown as PrismaService,
      ridesServiceMock as unknown as RidesService,
    );
  });

  it('should rank online driver candidates by weighted score formula', async () => {
    prismaMock.driverLocation.findMany.mockResolvedValue([
      {
        driverProfileId: 'driver-1',
        latitude: 23.81,
        longitude: 90.41,
        driverProfile: {
          id: 'driver-1',
          userId: 'user-driver-1',
          rating: 4.8,
          status: 'APPROVED',
          isOnline: true,
        },
      },
      {
        driverProfileId: 'driver-2',
        latitude: 23.82,
        longitude: 90.42,
        driverProfile: {
          id: 'driver-2',
          userId: 'user-driver-2',
          rating: 5.0,
          status: 'APPROVED',
          isOnline: true,
        },
      },
    ]);

    const candidates = await service.findCandidateDrivers(
      'ride-123',
      23.8103,
      90.4125,
      [],
    );

    expect(candidates).toHaveLength(2);
    expect(candidates[0].score).toBeGreaterThan(0);
  });
});
