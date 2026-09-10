import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { RidesService } from '../rides/rides.service';

export interface CandidateDriver {
  driverId: string;
  userId: string;
  distanceKm: number;
  etaMinutes: number;
  rating: number;
  score: number;
}

@Injectable()
export class DispatchService {
  private readonly logger = new Logger(DispatchService.name);

  constructor(
    private prisma: PrismaService,
    private ridesService: RidesService,
  ) {}

  async findCandidateDrivers(
    rideId: string,
    pickupLat: number,
    pickupLng: number,
    excludedDriverIds: string[] = [],
  ): Promise<CandidateDriver[]> {
    // Query online & approved drivers
    const onlineDrivers = await this.prisma.driverLocation.findMany({
      where: {
        status: 'ONLINE',
        driverProfile: {
          status: 'APPROVED',
          isOnline: true,
          userId: {
            notIn: excludedDriverIds,
          },
        },
      },
      include: {
        driverProfile: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!onlineDrivers || onlineDrivers.length === 0) {
      return [];
    }

    // Step 1 & 2: Filter drivers within 5km and take top 10 candidates by distance
    const candidatesWithDistance = onlineDrivers
      .map((dl) => {
        const dist = this.ridesService.calculateHaversineDistance(
          pickupLat,
          pickupLng,
          dl.latitude,
          dl.longitude,
        );
        return {
          driverId: dl.driverProfile.id,
          userId: dl.driverProfile.userId,
          rating: dl.driverProfile.rating || 5.0,
          distanceKm: dist,
        };
      })
      .filter((c) => c.distanceKm <= 5.0)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, 10);

    // Step 3 & 4: For top 5, compute ETA and weighted score: (etaScore * 0.6) + (ratingScore * 0.4)
    const top5 = candidatesWithDistance.slice(0, 5);
    const scoredCandidates: CandidateDriver[] = top5.map((c) => {
      // Mock / calculate ETA (e.g. assuming 25 km/h average speed in city)
      const etaMinutes = Math.max(1, Math.round((c.distanceKm / 25) * 60));
      const etaScore = 1 / etaMinutes;
      const ratingScore = c.rating / 5.0;
      const score = etaScore * 0.6 + ratingScore * 0.4;

      return {
        ...c,
        etaMinutes,
        score,
      };
    });

    // Rank candidates by highest score
    scoredCandidates.sort((a, b) => b.score - a.score);

    return scoredCandidates;
  }

  async dispatchRide(rideId: string, maxAttempts = 5) {
    const ride = await this.ridesService.getRideById(rideId);
    let attempts = 0;
    const excludedIds = [...(ride.declinedDriverIds || [])];

    while (attempts < maxAttempts) {
      const candidates = await this.findCandidateDrivers(
        rideId,
        ride.pickupLatitude,
        ride.pickupLongitude,
        excludedIds,
      );

      if (candidates.length === 0) {
        this.logger.warn(`No online drivers available within 5km for ride ${rideId}`);
        break;
      }

      const topCandidate = candidates[0];
      this.logger.log(
        `Attempt ${attempts + 1}/${maxAttempts}: Dispatching ride ${rideId} to driver ${topCandidate.driverId} (User ${topCandidate.userId}) with ETA ${topCandidate.etaMinutes} mins`,
      );

      // In real-time flow, Socket.IO gateway emits `server:ride:dispatched` to topCandidate.userId
      // If driver accepts, return success. If declined or timed out, exclude driver & retry.
      excludedIds.push(topCandidate.userId);
      attempts++;
    }

    if (attempts >= maxAttempts) {
      this.logger.warn(`Dispatch failed after ${maxAttempts} attempts for ride ${rideId}`);
      return { success: false, reason: 'NO_DRIVERS_AVAILABLE', attempts };
    }

    return { success: true, attempts };
  }
}
