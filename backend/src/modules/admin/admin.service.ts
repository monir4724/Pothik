import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { PricingService } from '../pricing/pricing.service';
import { UpdatePricingRuleDto } from '../pricing/dto/pricing.dto';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private pricingService: PricingService,
  ) {}

  async getAllDrivers() {
    return this.prisma.driverProfile.findMany({
      include: {
        user: true,
        vehicles: true,
        documents: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDriverById(driverProfileId: string) {
    const driver = await this.prisma.driverProfile.findUnique({
      where: { id: driverProfileId },
      include: {
        user: true,
        vehicles: true,
        documents: true,
        driverLocation: true,
      },
    });

    if (!driver) {
      throw new NotFoundException('Driver profile not found');
    }

    return driver;
  }

  async approveDriver(driverProfileId: string) {
    const driver = await this.getDriverById(driverProfileId);
    return this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: { status: 'APPROVED' },
    });
  }

  async rejectDriver(driverProfileId: string) {
    const driver = await this.getDriverById(driverProfileId);
    return this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: { status: 'REJECTED' },
    });
  }

  async suspendDriver(driverProfileId: string) {
    const driver = await this.getDriverById(driverProfileId);
    return this.prisma.driverProfile.update({
      where: { id: driverProfileId },
      data: { status: 'SUSPENDED', isOnline: false },
    });
  }

  async getAllRides() {
    return this.prisma.ride.findMany({
      include: {
        passenger: true,
        driver: true,
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getLiveRides() {
    return this.prisma.ride.findMany({
      where: {
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
                driverLocation: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getRideById(rideId: string) {
    const ride = await this.prisma.ride.findUnique({
      where: { id: rideId },
      include: {
        passenger: true,
        driver: true,
        payment: true,
        sosRequests: true,
      },
    });

    if (!ride) {
      throw new NotFoundException('Ride not found');
    }

    return ride;
  }

  async getAllPassengers() {
    return this.prisma.user.findMany({
      where: { role: 'PASSENGER' },
      include: {
        passengerRides: true,
        guardians: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPricing() {
    return this.pricingService.getPricingRules();
  }

  async updatePricing(id: string, dto: UpdatePricingRuleDto) {
    return this.pricingService.updatePricingRule(id, dto);
  }

  async getCommissionDebts() {
    return this.prisma.driverCommissionDebt.findMany({
      include: {
        driver: true,
        ride: true,
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getDashboardMetrics() {
    const [
      totalUsers,
      totalDrivers,
      pendingDrivers,
      totalRides,
      activeRides,
      completedRides,
      totalPayments,
      totalCommissionDebt,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: 'PASSENGER' } }),
      this.prisma.driverProfile.count(),
      this.prisma.driverProfile.count({ where: { status: 'PENDING' } }),
      this.prisma.ride.count(),
      this.prisma.ride.count({ where: { status: { notIn: ['COMPLETED', 'CANCELLED'] } } }),
      this.prisma.ride.count({ where: { status: 'COMPLETED' } }),
      this.prisma.payment.aggregate({ _sum: { amount: true, commissionAmount: true } }),
      this.prisma.driverCommissionDebt.aggregate({
        _sum: { amount: true },
        where: { status: 'UNPAID' },
      }),
    ]);

    return {
      totalPassengers: totalUsers,
      totalDrivers,
      pendingDriverApprovals: pendingDrivers,
      totalRides,
      activeRides,
      completedRides,
      totalRevenueCollected: totalPayments._sum.amount || 0,
      totalCommissionEarned: totalPayments._sum.commissionAmount || 0,
      outstandingCommissionDebt: totalCommissionDebt._sum.amount || 0,
    };
  }
}
