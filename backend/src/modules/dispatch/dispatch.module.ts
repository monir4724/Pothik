import { Module } from '@nestjs/common';
import { DispatchService } from './dispatch.service';
import { RidesModule } from '../rides/rides.module';
import { DriversModule } from '../drivers/drivers.module';

@Module({
  imports: [RidesModule, DriversModule],
  providers: [DispatchService],
  exports: [DispatchService],
})
export class DispatchModule {}
