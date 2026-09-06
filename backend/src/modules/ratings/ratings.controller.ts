import { Controller, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { RatingsService } from './ratings.service';
import { SubmitRatingDto } from './dto/ratings.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Ratings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class RatingsController {
  constructor(private readonly ratingsService: RatingsService) {}

  @Post('rides/:id/rating')
  @ApiOperation({ summary: 'Submit post-ride rating for passenger/driver' })
  async submitRating(
    @CurrentUser('id') userId: string,
    @Param('id') rideId: string,
    @Body() dto: SubmitRatingDto,
  ) {
    return this.ratingsService.submitRating(userId, rideId, dto);
  }
}
