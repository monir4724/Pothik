import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SosService } from './sos.service';
import { CreateGuardianDto, TriggerSosDto } from './dto/sos.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('SOS')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class SosController {
  constructor(private readonly sosService: SosService) {}

  @Get('guardians')
  @ApiOperation({ summary: 'Get current user emergency guardians' })
  async getGuardians(@CurrentUser('id') userId: string) {
    return this.sosService.getGuardians(userId);
  }

  @Post('guardians')
  @ApiOperation({ summary: 'Add an emergency guardian' })
  async createGuardian(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateGuardianDto,
  ) {
    return this.sosService.createGuardian(userId, dto);
  }

  @Delete('guardians/:id')
  @ApiOperation({ summary: 'Delete an emergency guardian' })
  async deleteGuardian(
    @CurrentUser('id') userId: string,
    @Param('id') guardianId: string,
  ) {
    return this.sosService.deleteGuardian(userId, guardianId);
  }

  @Post('sos')
  @ApiOperation({ summary: 'Trigger emergency SOS alert for active ride' })
  async triggerSos(
    @CurrentUser('id') passengerId: string,
    @Body() dto: TriggerSosDto,
  ) {
    return this.sosService.triggerSos(passengerId, dto);
  }

  @Patch('sos/:id/resolve')
  @ApiOperation({ summary: 'Resolve an active SOS emergency alert' })
  async resolveSos(@Param('id') id: string) {
    return this.sosService.resolveSos(id);
  }
}
