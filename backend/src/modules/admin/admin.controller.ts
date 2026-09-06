import { Controller, Get, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { UpdatePricingRuleDto } from '../pricing/dto/pricing.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get operational dashboard metrics' })
  async getDashboardMetrics() {
    return this.adminService.getDashboardMetrics();
  }

  @Get('drivers')
  @ApiOperation({ summary: 'List all driver profiles' })
  async getAllDrivers() {
    return this.adminService.getAllDrivers();
  }

  @Get('drivers/:id')
  @ApiOperation({ summary: 'Get driver profile by ID' })
  async getDriverById(@Param('id') id: string) {
    return this.adminService.getDriverById(id);
  }

  @Patch('drivers/:id/approve')
  @ApiOperation({ summary: 'Approve pending driver verification' })
  async approveDriver(@Param('id') id: string) {
    return this.adminService.approveDriver(id);
  }

  @Patch('drivers/:id/reject')
  @ApiOperation({ summary: 'Reject driver verification' })
  async rejectDriver(@Param('id') id: string) {
    return this.adminService.rejectDriver(id);
  }

  @Patch('drivers/:id/suspend')
  @ApiOperation({ summary: 'Suspend active driver account' })
  async suspendDriver(@Param('id') id: string) {
    return this.adminService.suspendDriver(id);
  }

  @Get('rides')
  @ApiOperation({ summary: 'List all system rides' })
  async getAllRides() {
    return this.adminService.getAllRides();
  }

  @Get('rides/live')
  @ApiOperation({ summary: 'List active live rides in progress' })
  async getLiveRides() {
    return this.adminService.getLiveRides();
  }

  @Get('rides/:id')
  @ApiOperation({ summary: 'Get ride details by ID' })
  async getRideById(@Param('id') id: string) {
    return this.adminService.getRideById(id);
  }

  @Get('passengers')
  @ApiOperation({ summary: 'List registered passengers' })
  async getAllPassengers() {
    return this.adminService.getAllPassengers();
  }

  @Get('pricing')
  @ApiOperation({ summary: 'Get pricing rules per vehicle type' })
  async getPricing() {
    return this.adminService.getPricing();
  }

  @Patch('pricing/:id')
  @ApiOperation({ summary: 'Update pricing rule by ID' })
  async updatePricing(
    @Param('id') id: string,
    @Body() dto: UpdatePricingRuleDto,
  ) {
    return this.adminService.updatePricing(id, dto);
  }

  @Get('commission-debts')
  @ApiOperation({ summary: 'Get commission debt overview for all drivers' })
  async getCommissionDebts() {
    return this.adminService.getCommissionDebts();
  }
}
