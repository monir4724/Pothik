import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateDriverProfileDto, UploadDriverDocumentDto, CreateVehicleDto } from './dto/drivers.dto';

@Injectable()
export class DriversService {
  constructor(private prisma: PrismaService) {}

  async createProfile(userId: string, dto: CreateDriverProfileDto) {
    const existing = await this.prisma.driverProfile.findUnique({
      where: { userId },
    });
    if (existing) {
      throw new BadRequestException('Driver profile already exists for this user');
    }

    const [driverProfile] = await this.prisma.$transaction([
      this.prisma.driverProfile.create({
        data: {
          userId,
          nidNumber: dto.nidNumber,
          drivingLicenseNumber: dto.drivingLicenseNumber,
          status: 'PENDING',
        },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { role: 'DRIVER' },
      }),
    ]);

    return driverProfile;
  }

  async uploadDocument(userId: string, dto: UploadDriverDocumentDto) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
    });
    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found. Please create a driver profile first.');
    }

    const document = await this.prisma.driverDocument.create({
      data: {
        driverProfileId: driverProfile.id,
        documentType: dto.documentType,
        documentUrl: dto.documentUrl,
        status: 'PENDING',
      },
    });

    return document;
  }

  async registerVehicle(userId: string, dto: CreateVehicleDto) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
    });
    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found. Please create a driver profile first.');
    }

    const vehicle = await this.prisma.vehicle.create({
      data: {
        driverProfileId: driverProfile.id,
        vehicleType: dto.vehicleType.toLowerCase(),
        make: dto.make,
        model: dto.model,
        year: dto.year,
        licensePlate: dto.licensePlate,
        color: dto.color,
      },
    });

    return vehicle;
  }

  async getDriverMe(userId: string) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
      include: {
        user: true,
        documents: true,
        vehicles: true,
        driverLocation: true,
      },
    });

    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found');
    }

    return driverProfile;
  }

  async getDriverStatus(userId: string) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
      select: {
        id: true,
        status: true,
        isOnline: true,
        rating: true,
        totalRides: true,
      },
    });

    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found');
    }

    return driverProfile;
  }

  async getEarnings(userId: string) {
    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
    });
    if (!driverProfile) {
      throw new NotFoundException('Driver profile not found');
    }

    const payments = await this.prisma.payment.findMany({
      where: {
        driverId: userId,
        status: 'CONFIRMED',
      },
      include: {
        ride: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const totalEarnings = payments.reduce((acc, curr) => acc + curr.amount, 0);
    const totalCommission = payments.reduce((acc, curr) => acc + curr.commissionAmount, 0);
    const netEarnings = totalEarnings - totalCommission;

    return {
      totalEarnings,
      totalCommission,
      netEarnings,
      totalTrips: payments.length,
      history: payments,
    };
  }
}
