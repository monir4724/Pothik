import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DriversService } from './drivers.service';
import { CreateDriverProfileDto, UploadDriverDocumentDto, CreateVehicleDto } from './dto/drivers.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Drivers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class DriversController {
  constructor(private readonly driversService: DriversService) {}

  @Post('drivers/profile')
  @ApiOperation({ summary: 'Create a driver profile' })
  async createProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateDriverProfileDto,
  ) {
    return this.driversService.createProfile(userId, dto);
  }

  @Post('drivers/documents')
  @ApiOperation({ summary: 'Upload a driver verification document' })
  async uploadDocument(
    @CurrentUser('id') userId: string,
    @Body() dto: UploadDriverDocumentDto,
  ) {
    return this.driversService.uploadDocument(userId, dto);
  }

  @Post('drivers/vehicle')
  @ApiOperation({ summary: 'Register a vehicle tied to driver profile' })
  async registerVehicle(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateVehicleDto,
  ) {
    return this.driversService.registerVehicle(userId, dto);
  }

  @Get('drivers/me')
  @ApiOperation({ summary: 'Get driver profile details' })
  async getDriverMe(@CurrentUser('id') userId: string) {
    return this.driversService.getDriverMe(userId);
  }

  @Get('drivers/me/status')
  @ApiOperation({ summary: 'Get driver verification and online status' })
  async getDriverStatus(@CurrentUser('id') userId: string) {
    return this.driversService.getDriverStatus(userId);
  }

  @Get('drivers/me/earnings')
  @ApiOperation({ summary: 'Get driver earnings summary and history' })
  async getEarnings(@CurrentUser('id') userId: string) {
    return this.driversService.getEarnings(userId);
  }
}
