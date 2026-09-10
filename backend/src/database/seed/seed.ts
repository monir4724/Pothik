import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const economyPricing = await prisma.pricingRule.upsert({
    where: { vehicleType: 'economy' },
    update: {
      baseFare: 30.0,
      perKmRate: 12.0,
      perMinuteRate: 1.5,
      minimumFare: 50.0,
      commissionRate: 0.2,
      isActive: true,
    },
    create: {
      vehicleType: 'economy',
      baseFare: 30.0,
      perKmRate: 12.0,
      perMinuteRate: 1.5,
      minimumFare: 50.0,
      commissionRate: 0.2,
      isActive: true,
    },
  });

  console.log('Seeded economy pricing rule:', economyPricing);
}

main()
  .catch((e) => {
    console.error('Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
