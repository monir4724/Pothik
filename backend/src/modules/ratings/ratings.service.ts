import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { SubmitRatingDto } from './dto/ratings.dto';

@Injectable()
export class RatingsService {
  constructor(private prisma: PrismaService) {}

  async submitRating(userId: string, rideId: string, dto: SubmitRatingDto) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
    });

    if (!ride) {
      throw new NotFoundException('Ride not found');
    }

    if (ride.status !== 'COMPLETED') {
      throw new BadRequestException('Ratings can only be submitted for completed rides');
    }

    const isPassenger = ride.passengerId === userId;
    const isDriver = ride.driverId === userId;

    if (!isPassenger && !isDriver) {
      throw new ForbiddenException('You are not a participant in this ride');
    }

    const targetUserId = isPassenger ? ride.driverId : ride.passengerId;

    if (!targetUserId) {
      throw new BadRequestException('Target user to rate not found');
    }

    // Update target user rating (weighted running average)
    const targetUser = await this.prisma.user.findUnique({
      where: { id: targetUserId },
    });

    if (targetUser) {
      const currentRating = targetUser.rating || 5.0;
      const newRating = Math.round(((currentRating + dto.rating) / 2) * 100) / 100;

      await this.prisma.user.update({
        where: { id: targetUserId },
        data: { rating: newRating },
      });

      if (!isPassenger) {
        // Driver rating passenger
        await this.prisma.driverProfile.updateMany({
          where: { userId: targetUserId },
          data: { rating: newRating },
        });
      }
    }

    return {
      message: 'Rating submitted successfully',
      rideId,
      ratedUserId: targetUserId,
      givenRating: dto.rating,
      comment: dto.comment,
    };
  }
}
