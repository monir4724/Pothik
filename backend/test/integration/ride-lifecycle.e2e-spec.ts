import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '../../src/app.module';
import { PrismaService } from '../../src/database/prisma.service';
import { TransformInterceptor } from '../../src/common/interceptors/transform.interceptor';
import { HttpExceptionFilter } from '../../src/common/filters/http-exception.filter';
import { AuthService } from '../../src/modules/auth/auth.service';
import { RidesService } from '../../src/modules/rides/rides.service';
import { PaymentsService } from '../../src/modules/payments/payments.service';
import { RatingsService } from '../../src/modules/ratings/ratings.service';

describe('Ride Lifecycle E2E Test Suite', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let authService: AuthService;
  let ridesService: RidesService;
  let paymentsService: PaymentsService;
  let ratingsService: RatingsService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());

    prisma = moduleFixture.get<PrismaService>(PrismaService);
    authService = moduleFixture.get<AuthService>(AuthService);
    ridesService = moduleFixture.get<RidesService>(RidesService);
    paymentsService = moduleFixture.get<PaymentsService>(PaymentsService);
    ratingsService = moduleFixture.get<RatingsService>(RatingsService);

    await app.init();
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  it('should complete full ride lifecycle: request -> accept -> arrive -> otp verify -> complete -> cash confirm -> rating', async () => {
    // 1. Create Passenger & Driver Users in DB
    const passenger = await prisma.user.create({
      data: {
        phone: '+8801700000001',
        name: 'Passenger Test',
        role: 'PASSENGER',
      },
    });

    const driverUser = await prisma.user.create({
      data: {
        phone: '+8801700000002',
        name: 'Driver Test',
        role: 'DRIVER',
      },
    });

    const driverProfile = await prisma.driverProfile.create({
      data: {
        userId: driverUser.id,
        nidNumber: '1999887766554',
        drivingLicenseNumber: 'DL-112233',
        status: 'APPROVED',
        isOnline: true,
      },
    });

    const vehicle = await prisma.vehicle.create({
      data: {
        driverProfileId: driverProfile.id,
        vehicleType: 'economy',
        make: 'Toyota',
        model: 'Corolla',
        year: 2020,
        licensePlate: 'DHAKA-METRO-KA-99-0011',
        color: 'White',
      },
    });

    // 2. Request Ride
    const ride = await ridesService.createRide(passenger.id, {
      pickupLat: 23.8103,
      pickupLng: 90.4125,
      pickupAddress: 'Gulshan 2, Dhaka',
      dropoffLat: 23.794,
      dropoffLng: 90.4043,
      dropoffAddress: 'Banani, Dhaka',
      vehicleType: 'economy',
    });

    expect(ride.status).toBe('REQUESTED');
    expect(ride.otp).toBeDefined();

    // 3. Driver Accepts Ride
    const acceptedRide = await ridesService.acceptRide(driverUser.id, ride.id);
    expect(acceptedRide.status).toBe('ACCEPTED');
    expect(acceptedRide.driverId).toBe(driverUser.id);

    // 4. Driver Arrives at Pickup
    const arrivedRide = await ridesService.markArrived(driverUser.id, ride.id);
    expect(arrivedRide.status).toBe('DRIVER_ARRIVED');

    // 5. Driver Verifies OTP and Starts Trip
    const inProgressRide = await ridesService.verifyOtp(
      driverUser.id,
      ride.id,
      { otp: ride.otp },
    );
    expect(inProgressRide.status).toBe('IN_PROGRESS');

    // 6. Driver Completes Trip
    const completedRide = await ridesService.completeRide(
      driverUser.id,
      ride.id,
    );
    expect(completedRide.status).toBe('COMPLETED');

    // 7. Cash Payment Confirmation & 20% Commission Debt Calculation
    const paymentResult = await paymentsService.confirmCashPayment(
      driverUser.id,
      ride.id,
    );
    expect(paymentResult.payment.status).toBe('CONFIRMED');
    expect(paymentResult.commissionDebt.amount).toBe(
      Math.round(completedRide.estimatedFare * 0.2 * 100) / 100,
    );

    // 8. Mutual Post-Ride Rating
    const ratingResult = await ratingsService.submitRating(
      passenger.id,
      ride.id,
      {
        rating: 5,
        comment: 'Excellent trip!',
      },
    );
    expect(ratingResult.givenRating).toBe(5);

    // Clean up test records
    await prisma.driverCommissionDebt.deleteMany({
      where: { rideId: ride.id },
    });
    await prisma.payment.deleteMany({ where: { rideId: ride.id } });
    await prisma.ride.deleteMany({ where: { id: ride.id } });
    await prisma.vehicle.deleteMany({ where: { id: vehicle.id } });
    await prisma.driverProfile.deleteMany({ where: { id: driverProfile.id } });
    await prisma.user.deleteMany({
      where: { id: { in: [passenger.id, driverUser.id] } },
    });
  });
});
