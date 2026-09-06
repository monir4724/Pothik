import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private prisma: PrismaService) {}

  async sendPushNotification(
    userId: string,
    title: string,
    body: string,
    data?: any,
  ) {
    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: { userId },
    });

    if (deviceTokens.length > 0) {
      deviceTokens.forEach((dt) => {
        this.logger.log(
          `[FCM Push Notification Stub] Sending to ${dt.fcmToken} (${dt.deviceType}): ${title} - ${body}`,
        );
      });
    }

    const notification = await this.prisma.notification.create({
      data: {
        userId,
        title,
        body,
        data: data || {},
      },
    });

    return notification;
  }

  async getUserNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true },
    });
  }
}
