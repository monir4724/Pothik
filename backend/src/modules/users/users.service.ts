import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { UpdateUserProfileDto, RegisterDeviceTokenDto } from './dto/users.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        driverProfile: {
          include: {
            vehicles: true,
            documents: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    return user;
  }

  async updateProfile(userId: string, dto: UpdateUserProfileDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.email && { email: dto.email }),
        ...(dto.profilePictureUrl && { profilePictureUrl: dto.profilePictureUrl }),
      },
    });

    return user;
  }

  async registerDeviceToken(userId: string, dto: RegisterDeviceTokenDto) {
    const deviceToken = await this.prisma.deviceToken.upsert({
      where: { fcmToken: dto.fcmToken },
      update: {
        userId,
        deviceType: dto.deviceType,
      },
      create: {
        userId,
        fcmToken: dto.fcmToken,
        deviceType: dto.deviceType,
      },
    });

    return deviceToken;
  }
}
