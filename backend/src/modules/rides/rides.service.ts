import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { PricingService } from '../pricing/pricing.service';
import {
  EstimateRideDto,
  CreateRideDto,
  CancelRideDto,
  VerifyOtpDto,
  DeclineRideDto,
} from './dto/rides.dto';
import { RideStatus } from '@prisma/client';

@Injectable()
export class RidesService {
  constructor(
    private prisma: PrismaService,
    private pricingService: PricingService,
  ) {}

  // Distance calculation using Haversine formula
  calculateHaversineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const R = 6371; // Radius of Earth in kilometers
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(R * c * 100) / 100;
  }

  async estimate(dto: EstimateRideDto) {
    const vehicleType = dto.vehicleType || 'economy';
    const distanceKm = this.calculateHaversineDistance(
      dto.pickupLat,
      dto.pickupLng,
      dto.dropoffLat,
      dto.dropoffLng,
    );
    // Assume average speed 20 km/h in Dhaka traffic -> durationMin = (distance / 20) * 60
    const durationMin = Math.max(5, Math.round((distanceKm / 20) * 60));

    const { estimatedFare, pricingRule } =
      await this.pricingService.calculateFare(
        vehicleType,
        distanceKm,
        durationMin,
      );

    return {
      vehicleType,
      estimatedDistanceKm: distanceKm,
      estimatedDurationMin: durationMin,
      estimatedFare,
      pricingRule: {
        baseFare: pricingRule.baseFare,
        perKmRate: pricingRule.perKmRate,
        perMinuteRate: pricingRule.perMinuteRate,
        minimumFare: pricingRule.minimumFare,
      },
    };
  }

  async createRide(passengerId: string, dto: CreateRideDto) {
    // Check if passenger already has an active ride
    const activeRide = await this.prisma.ride.findFirst({
      where: {
        passengerId,
        status: {
          notIn: ['COMPLETED', 'CANCELLED'],
        },
      },
    });

    if (activeRide) {
      throw new BadRequestException(
        'You already have an active ride request or trip in progress',
      );
    }

    const vehicleType = dto.vehicleType || 'economy';
    const estimation = await this.estimate({
      pickupLat: dto.pickupLat,
      pickupLng: dto.pickupLng,
      dropoffLat: dto.dropoffLat,
      dropoffLng: dto.dropoffLng,
      vehicleType,
    });

    // Generate 4-digit OTP for ride verification
    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    const ride = await this.prisma.ride.create({
      data: {
        passengerId,
        pickupLatitude: dto.pickupLat,
        pickupLongitude: dto.pickupLng,
        pickupAddress: dto.pickupAddress,
        dropoffLatitude: dto.dropoffLat,
        dropoffLongitude: dto.dropoffLng,
        dropoffAddress: dto.dropoffAddress,
        estimatedFare: estimation.estimatedFare,
        estimatedDistanceKm: estimation.estimatedDistanceKm,
        estimatedDurationMin: estimation.estimatedDurationMin,
        otp,
        status: 'REQUESTED',
      },
      include: {
        passenger: true,
      },
    });

    return ride;
  }

  async getActiveRide(userId: string) {
    const ride = await this.prisma.ride.findFirst({
      where: {
        OR: [{ passengerId: userId }, { driverId: userId }],
        status: {
          notIn: ['COMPLETED', 'CANCELLED'],
        },
      },
      include: {
        passenger: true,
        driver: {
          include: {
            driverProfile: {
              include: {
                vehicles: true,
              },
            },
          },
        },
      },
    });

    return ride || null;
  }

  async getRideById(id: string) {
    const ride = await this.prisma.ride.findUnique({
      where: { id },
      include: {
        passenger: true,
        driver: {
          include: {
            driverProfile: {
              include: {
                vehicles: true,
              },
            },
          },
        },
        payment: true,
      },
    });

    if (!ride) {
      throw new NotFoundException('Ride not found');
    }

    return ride;
  }

  async getRideHistory(userId: string) {
    const rides = await this.prisma.ride.findMany({
      where: {
        OR: [{ passengerId: userId }, { driverId: userId }],
      },
      include: {
        passenger: true,
        driver: true,
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return rides;
  }

  async validateAndTransitionState(
    rideId: string,
    allowedFromStates: RideStatus[],
    toState: RideStatus,
  ) {
    const ride = await this.getRideById(rideId);
    if (!allowedFromStates.includes(ride.status)) {
      throw new BadRequestException(
        `Cannot transition ride status from '${ride.status}' to '${toState}'`,
      );
    }
    return ride;
  }

  async cancelRide(userId: string, rideId: string, dto: CancelRideDto) {
    const ride = await this.getRideById(rideId);

    if (ride.passengerId !== userId && ride.driverId !== userId) {
      throw new ForbiddenException('You are not authorized to cancel this ride');
    }

    if (['COMPLETED', 'CANCELLED'].includes(ride.status)) {
      throw new BadRequestException('Ride is already completed or cancelled');
    }

    const cancelledBy = ride.passengerId === userId ? 'PASSENGER' : 'DRIVER';

    const updatedRide = await this.prisma.ride.update({
      where: { id: rideId },
      data: {
        status: 'CANCELLED',
        cancelledBy,
        cancellationReason: dto.reason || 'User cancelled ride',
      },
      include: {
        passenger: true,
        driver: true,
      },
    });

    return updatedRide;
  }

  async acceptRide(driverId: string, rideId: string) {
    await this.validateAndTransitionState(
      rideId,
      ['REQUESTED'],
      'ACCEPTED',
    );

    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId: driverId },
      include: { vehicles: true },
    });

    if (!driverProfile || driverProfile.status !== 'APPROVED') {
      throw new BadRequestException('Only approved drivers can accept rides');
    }

    const primaryVehicle = driverProfile.vehicles[0];

    const updatedRide = await this.prisma.ride.update({
      where: { id: rideId },
      data: {
        driverId,
        vehicleId: primaryVehicle?.id || null,
        status: 'ACCEPTED',
      },
      include: {
        passenger: true,
        driver: {
          include: {
            driverProfile: {
              include: {
                vehicles: true,
              },
            },
          },
        },
      },
    });

    return updatedRide;
  }

  async declineRide(driverId: string, rideId: string, dto: DeclineRideDto) {
    const ride = await this.getRideById(rideId);

    if (!ride.declinedDriverIds.includes(driverId)) {
      await this.prisma.ride.update({
        where: { id: rideId },
        data: {
          declinedDriverIds: {
            push: driverId,
          },
        },
      });
    }

    return { message: 'Ride declined by driver', rideId };
  }

  async markArrived(driverId: string, rideId: string) {
    const ride = await this.getRideById(rideId);
    if (ride.driverId !== driverId) {
      throw new ForbiddenException('You are not assigned to this ride');
    }

    await this.validateAndTransitionState(
      rideId,
      ['ACCEPTED', 'DRIVER_ARRIVING'],
      'DRIVER_ARRIVED',
    );

    const updatedRide = await this.prisma.ride.update({
      where: { id: rideId },
      data: { status: 'DRIVER_ARRIVED' },
      include: { passenger: true, driver: true },
    });

    return updatedRide;
  }

  async verifyOtp(driverId: string, rideId: string, dto: VerifyOtpDto) {
    const ride = await this.getRideById(rideId);
    if (ride.driverId !== driverId) {
      throw new ForbiddenException('You are not assigned to this ride');
    }

    await this.validateAndTransitionState(
      rideId,
      ['DRIVER_ARRIVED', 'WAITING'],
      'IN_PROGRESS',
    );

    if (ride.otp !== dto.otp) {
      throw new BadRequestException('Invalid OTP code provided');
    }

    const updatedRide = await this.prisma.ride.update({
      where: { id: rideId },
      data: { status: 'IN_PROGRESS' },
      include: { passenger: true, driver: true },
    });

    return updatedRide;
  }

  async completeRide(driverId: string, rideId: string) {
    const ride = await this.getRideById(rideId);
    if (ride.driverId !== driverId) {
      throw new ForbiddenException('You are not assigned to this ride');
    }

    await this.validateAndTransitionState(
      rideId,
      ['IN_PROGRESS'],
      'COMPLETED',
    );

    const updatedRide = await this.prisma.ride.update({
      where: { id: rideId },
      data: {
        status: 'COMPLETED',
        actualFare: ride.estimatedFare, // default actual fare to estimated fare
      },
      include: { passenger: true, driver: true },
    });

    // Increment driver total rides count
    await this.prisma.driverProfile.updateMany({
      where: { userId: driverId },
      data: {
        totalRides: { increment: 1 },
      },
    });

    return updatedRide;
  }
}
