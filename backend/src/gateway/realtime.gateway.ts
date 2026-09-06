import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Logger, UseGuards } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { RidesService } from '../modules/rides/rides.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class RealtimeGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);
  private driverLocationsCache = new Map<string, any>();

  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private prisma: PrismaService,
    private ridesService: RidesService,
  ) {
    // Flush cached driver location updates to Postgres DB every 10 seconds
    setInterval(() => this.flushDriverLocationsToDb(), 10000);
  }

  async handleConnection(client: Socket) {
    try {
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        client.disconnect();
        return;
      }

      const secret =
        this.configService.get<string>('jwt.accessSecret') ||
        'super_secret_access_key_pothik_2026';
      const payload = this.jwtService.verify(token, { secret });
      const userId = payload.sub;
      const role = payload.role;

      client.data.user = { userId, role };

      // Join client to role-based rooms
      if (role === 'PASSENGER') {
        client.join(`passenger-${userId}`);
      } else if (role === 'DRIVER') {
        client.join(`driver-${userId}`);
      } else if (role === 'ADMIN') {
        client.join('admin');
      }

      this.logger.log(`Client connected: ${client.id} (User: ${userId}, Role: ${role})`);
    } catch (err) {
      this.logger.warn(`Unauthorized WebSocket connection attempt: ${err.message}`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('driver:location:update')
  async handleLocationUpdate(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { lat: number; lng: number; heading?: number; accuracy?: number; timestamp?: number; rideId?: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    // Cache driver location in memory / Redis
    this.driverLocationsCache.set(userId, {
      ...payload,
      updatedAt: new Date(),
    });

    if (payload.rideId) {
      // Broadcast driver location to ride room
      this.server.to(`ride-${payload.rideId}`).emit('server:driver:location', {
        rideId: payload.rideId,
        lat: payload.lat,
        lng: payload.lng,
        heading: payload.heading || 0,
      });
    }
  }

  @SubscribeMessage('driver:status:change')
  async handleStatusChange(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { status: 'ONLINE' | 'BREAK' | 'OFFLINE' },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    const driverProfile = await this.prisma.driverProfile.findUnique({
      where: { userId },
    });

    if (!driverProfile) return;

    const isOnline = payload.status === 'ONLINE';

    await this.prisma.driverProfile.update({
      where: { id: driverProfile.id },
      data: { isOnline },
    });

    await this.prisma.driverLocation.upsert({
      where: { driverProfileId: driverProfile.id },
      update: {
        status: payload.status === 'ONLINE' ? 'ONLINE' : 'OFFLINE',
      },
      create: {
        driverProfileId: driverProfile.id,
        status: payload.status === 'ONLINE' ? 'ONLINE' : 'OFFLINE',
        latitude: 23.8103,
        longitude: 90.4125,
      },
    });

    client.emit('server:driver:status', { status: payload.status });
  }

  @SubscribeMessage('driver:ride:accept')
  async handleAcceptRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    const ride = await this.ridesService.acceptRide(userId, payload.rideId);
    client.join(`ride-${ride.id}`);

    // Emit server:ride:accepted to passenger
    this.server.to(`passenger-${ride.passengerId}`).emit('server:ride:accepted', {
      rideId: ride.id,
      driver: {
        name: ride.driver?.name,
        phone: ride.driver?.phone,
        rating: ride.driver?.rating,
      },
    });
  }

  @SubscribeMessage('driver:ride:decline')
  async handleDeclineRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string; reason?: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    await this.ridesService.declineRide(userId, payload.rideId, { reason: payload.reason });
  }

  @SubscribeMessage('driver:arrived:pickup')
  async handleArrived(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    const ride = await this.ridesService.markArrived(userId, payload.rideId);
    this.server.to(`passenger-${ride.passengerId}`).emit('server:driver:arrived', {
      rideId: ride.id,
    });
  }

  @SubscribeMessage('driver:ride:complete')
  async handleCompleteRide(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { rideId: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId) return;

    const ride = await this.ridesService.completeRide(userId, payload.rideId);
    this.server.to(`passenger-${ride.passengerId}`).emit('server:ride:completed', {
      rideId: ride.id,
      fare: ride.actualFare,
    });
  }

  private async flushDriverLocationsToDb() {
    if (this.driverLocationsCache.size === 0) return;

    for (const [userId, loc] of this.driverLocationsCache.entries()) {
      try {
        const dp = await this.prisma.driverProfile.findUnique({
          where: { userId },
        });

        if (dp) {
          await this.prisma.driverLocation.upsert({
            where: { driverProfileId: dp.id },
            update: {
              latitude: loc.lat,
              longitude: loc.lng,
              heading: loc.heading || 0,
              accuracy: loc.accuracy || 0,
            },
            create: {
              driverProfileId: dp.id,
              latitude: loc.lat,
              longitude: loc.lng,
              heading: loc.heading || 0,
              accuracy: loc.accuracy || 0,
              status: 'ONLINE',
            },
          });
        }
      } catch (err) {
        this.logger.error(`Error flushing location for user ${userId}: ${err.message}`);
      }
    }
  }
}
