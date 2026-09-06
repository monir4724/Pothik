import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { UpdatePricingRuleDto, CreatePricingRuleDto } from './dto/pricing.dto';

@Injectable()
export class PricingService {
  constructor(private prisma: PrismaService) {}

  async getPricingRules() {
    return this.prisma.pricingRule.findMany({
      where: { isActive: true },
    });
  }

  async getRuleByVehicleType(vehicleType: string) {
    const rule = await this.prisma.pricingRule.findUnique({
      where: { vehicleType: vehicleType.toLowerCase() },
    });

    if (!rule) {
      // Fallback to economy rule if specific vehicle rule does not exist
      const defaultRule = await this.prisma.pricingRule.findUnique({
        where: { vehicleType: 'economy' },
      });
      if (!defaultRule) {
        throw new NotFoundException(`Pricing rule for ${vehicleType} not found`);
      }
      return defaultRule;
    }

    return rule;
  }

  async calculateFare(vehicleType: string, distanceKm: number, durationMin: number): Promise<{ estimatedFare: number; pricingRule: any }> {
    const rule = await this.getRuleByVehicleType(vehicleType);
    const calculated = rule.baseFare + distanceKm * rule.perKmRate + durationMin * rule.perMinuteRate;
    const finalFare = Math.max(rule.minimumFare, Math.round(calculated * 100) / 100);

    return {
      estimatedFare: finalFare,
      pricingRule: rule,
    };
  }

  async createPricingRule(dto: CreatePricingRuleDto) {
    return this.prisma.pricingRule.upsert({
      where: { vehicleType: dto.vehicleType.toLowerCase() },
      update: {
        baseFare: dto.baseFare,
        perKmRate: dto.perKmRate,
        perMinuteRate: dto.perMinuteRate,
        minimumFare: dto.minimumFare,
        commissionRate: dto.commissionRate ?? 0.20,
      },
      create: {
        vehicleType: dto.vehicleType.toLowerCase(),
        baseFare: dto.baseFare,
        perKmRate: dto.perKmRate,
        perMinuteRate: dto.perMinuteRate,
        minimumFare: dto.minimumFare,
        commissionRate: dto.commissionRate ?? 0.20,
      },
    });
  }

  async updatePricingRule(id: string, dto: UpdatePricingRuleDto) {
    const existing = await this.prisma.pricingRule.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException('Pricing rule not found');
    }

    return this.prisma.pricingRule.update({
      where: { id },
      data: dto,
    });
  }
}
