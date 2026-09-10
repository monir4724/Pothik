import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import databaseConfig from './config/database.config';
import redisConfig from './config/redis.config';
import jwtConfig from './config/jwt.config';
import { PrismaModule } from './database/prisma.module';
import { HealthController } from './health/health.controller';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { DriversModule } from './modules/drivers/drivers.module';
import { VehiclesModule } from './modules/vehicles/vehicles.module';
import { PricingModule } from './modules/pricing/pricing.module';
import { RidesModule } from './modules/rides/rides.module';
import { DispatchModule } from './modules/dispatch/dispatch.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { RatingsModule } from './modules/ratings/ratings.module';
import { SosModule } from './modules/sos/sos.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AdminModule } from './modules/admin/admin.module';
import { RealtimeModule } from './gateway/realtime.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig, redisConfig, jwtConfig],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    DriversModule,
    VehiclesModule,
    PricingModule,
    RidesModule,
    DispatchModule,
    PaymentsModule,
    RatingsModule,
    SosModule,
    NotificationsModule,
    AdminModule,
    RealtimeModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
