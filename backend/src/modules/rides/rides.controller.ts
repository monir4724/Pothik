import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RidesService } from './rides.service';
import {
  EstimateRideDto,
  CreateRideDto,
  CancelRideDto,
  VerifyOtpDto,
  DeclineRideDto,
} from './dto/rides.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Rides')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('rides')
export class RidesController {
  constructor(private readonly ridesService: RidesService) {}

  @Get('estimate')
  @ApiOperation({ summary: 'Calculate estimated fare and route details' })
  async estimate(@Query() dto: EstimateRideDto) {
    return this.ridesService.estimate(dto);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new ride request' })
  async createRide(
    @CurrentUser('id') passengerId: string,
    @Body() dto: CreateRideDto,
  ) {
    return this.ridesService.createRide(passengerId, dto);
  }

  @Get('active')
  @ApiOperation({ summary: 'Get active ride for current passenger/driver' })
  async getActiveRide(@CurrentUser('id') userId: string) {
    return this.ridesService.getActiveRide(userId);
  }

  @Get('history')
  @ApiOperation({ summary: 'Get ride history for current user' })
  async getRideHistory(@CurrentUser('id') userId: string) {
    return this.ridesService.getRideHistory(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get ride details by ID' })
  async getRideById(@Param('id') id: string) {
    return this.ridesService.getRideById(id);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a ride request or trip' })
  async cancelRide(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: CancelRideDto,
  ) {
    return this.ridesService.cancelRide(userId, id, dto);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: 'Driver accepts a dispatched ride' })
  async acceptRide(
    @CurrentUser('id') driverId: string,
    @Param('id') id: string,
  ) {
    return this.ridesService.acceptRide(driverId, id);
  }

  @Post(':id/decline')
  @ApiOperation({ summary: 'Driver declines a dispatched ride' })
  async declineRide(
    @CurrentUser('id') driverId: string,
    @Param('id') id: string,
    @Body() dto: DeclineRideDto,
  ) {
    return this.ridesService.declineRide(driverId, id, dto);
  }

  @Post(':id/arrived')
  @ApiOperation({ summary: 'Driver marks arrived at pickup location' })
  async markArrived(
    @CurrentUser('id') driverId: string,
    @Param('id') id: string,
  ) {
    return this.ridesService.markArrived(driverId, id);
  }

  @Post(':id/verify-otp')
  @ApiOperation({ summary: 'Driver verifies passenger OTP to start trip' })
  async verifyOtp(
    @CurrentUser('id') driverId: string,
    @Param('id') id: string,
    @Body() dto: VerifyOtpDto,
  ) {
    return this.ridesService.verifyOtp(driverId, id, dto);
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Driver completes trip upon reaching dropoff' })
  async completeRide(
    @CurrentUser('id') driverId: string,
    @Param('id') id: string,
  ) {
    return this.ridesService.completeRide(driverId, id);
  }
}
