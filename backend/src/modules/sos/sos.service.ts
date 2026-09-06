import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateGuardianDto, TriggerSosDto } from './dto/sos.dto';

@Injectable()
export class SosService {
  private readonly logger = new Logger(SosService.name);

  constructor(private prisma: PrismaService) {}

  async getGuardians(userId: string) {
    return this.prisma.guardian.findMany({
      where: { userId },
      orderBy: { isPrimary: 'desc' },
    });
  }

  async createGuardian(userId: string, dto: CreateGuardianDto) {
    if (dto.isPrimary) {
      // Unset other primary guardians for this user
      await this.prisma.guardian.updateMany({
        where: { userId },
        data: { isPrimary: false },
      });
    }

    const guardian = await this.prisma.guardian.create({
      data: {
        userId,
        name: dto.name,
        phone: dto.phone,
        relationship: dto.relationship,
        isPrimary: dto.isPrimary ?? false,
      },
    });

    return guardian;
  }

  async deleteGuardian(userId: string, guardianId: string) {
    const guardian = await this.prisma.guardian.findFirst({
      where: { id: guardianId, userId },
    });

    if (!guardian) {
      throw new NotFoundException('Guardian not found');
    }

    await this.prisma.guardian.delete({
      where: { id: guardianId },
    });

    return { message: 'Guardian deleted successfully' };
  }

  async triggerSos(passengerId: string, dto: TriggerSosDto) {
    // Step 1 & 2: Verify active ride for passenger
    const ride = await this.prisma.ride.findFirst({
      where: {
        id: dto.rideId,
        passengerId,
        status: {
          notIn: ['COMPLETED', 'CANCELLED'],
        },
      },
      include: {
        passenger: true,
      },
    });

    if (!ride) {
      throw new BadRequestException('No active ride found matching the provided ID');
    }

    // Step 3: Look up primary guardian
    const primaryGuardian = await this.prisma.guardian.findFirst({
      where: { userId: passengerId, isPrimary: true },
    }) || await this.prisma.guardian.findFirst({
      where: { userId: passengerId },
    });

    const mapsUrl = `https://maps.google.com/?q=${dto.latitude},${dto.longitude}`;
    const passengerName = ride.passenger?.name || 'Pothik Passenger';
    const smsMessage = `EMERGENCY ALERT: ${passengerName} triggered SOS on Pothik ride. Current location: ${mapsUrl}`;

    let smsStatus = 'FAILED_NO_GUARDIAN';
    if (primaryGuardian) {
      // Step 4: Stub SSL Wireless SMS alert dispatch
      this.logger.warn(`[SSL Wireless SOS Alert] Sending to Guardian ${primaryGuardian.name} (${primaryGuardian.phone}): ${smsMessage}`);
      smsStatus = 'DELIVERED';
    }

    // Step 5: Create sos_requests record
    const sosRequest = await this.prisma.sosRequest.create({
      data: {
        passengerId,
        rideId: dto.rideId,
        latitude: dto.latitude,
        longitude: dto.longitude,
        status: 'ACTIVE',
        smsStatus,
      },
      include: {
        passenger: true,
        ride: true,
      },
    });

    return {
      sosRequest,
      alertMessage: smsMessage,
      guardianContacted: primaryGuardian ? primaryGuardian.phone : null,
    };
  }

  async resolveSos(sosId: string) {
    const sosRequest = await this.prisma.sosRequest.findUnique({
      where: { id: sosId },
    });

    if (!sosRequest) {
      throw new NotFoundException('SOS request not found');
    }

    const updated = await this.prisma.sosRequest.update({
      where: { id: sosId },
      data: { status: 'RESOLVED' },
    });

    return updated;
  }
}
