import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';
import { RequestOtpDto, VerifyOtpDto, RefreshTokenDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private rateLimitMap = new Map<string, { count: number; resetAt: number }>();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  private checkRateLimit(phone: string) {
    const now = Date.now();
    const limit = this.rateLimitMap.get(phone);
    if (limit) {
      if (now > limit.resetAt) {
        this.rateLimitMap.set(phone, { count: 1, resetAt: now + 15 * 60 * 1000 });
      } else {
        if (limit.count >= 5) {
          throw new HttpException(
            'Too many OTP requests. Please try again after 15 minutes.',
            HttpStatus.TOO_MANY_REQUESTS,
          );
        }
        limit.count += 1;
      }
    } else {
      this.rateLimitMap.set(phone, { count: 1, resetAt: now + 15 * 60 * 1000 });
    }
  }

  async requestOtp(dto: RequestOtpDto) {
    this.checkRateLimit(dto.phone);

    // Generate 6 digit OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 mins

    await this.prisma.otpCode.create({
      data: {
        phone: dto.phone,
        code,
        expiresAt,
      },
    });

    // Mock/Stub SMS dispatch to SSL Wireless
    this.logger.log(`[SSL Wireless BD Stub] Sending OTP ${code} to ${dto.phone}`);

    return {
      message: 'OTP sent successfully',
      phone: dto.phone,
      // For development/testing ease, return otp in dev mode
      ...(process.env.NODE_ENV !== 'production' ? { devOtp: code } : {}),
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const otpRecord = await this.prisma.otpCode.findFirst({
      where: {
        phone: dto.phone,
        code: dto.code,
        isUsed: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Invalid or expired OTP code');
    }

    await this.prisma.otpCode.update({
      where: { id: otpRecord.id },
      data: { isUsed: true },
    });

    let user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      include: { driverProfile: true },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone: dto.phone,
          role: 'PASSENGER',
        },
        include: { driverProfile: true },
      });
    }

    const tokens = this.generateTokens(user);
    return {
      user,
      tokens,
    };
  }

  async refreshToken(dto: RefreshTokenDto) {
    try {
      const refreshSecret =
        this.configService.get<string>('jwt.refreshSecret') || 'super_secret_refresh_key_pothik_2026';
      const payload = this.jwtService.verify(dto.refreshToken, {
        secret: refreshSecret,
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      const tokens = this.generateTokens(user);
      return tokens;
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout() {
    return { message: 'Logged out successfully' };
  }

  private generateTokens(user: any) {
    const payload = { sub: user.id, phone: user.phone, role: user.role };
    const accessSecret =
      this.configService.get<string>('jwt.accessSecret') || 'super_secret_access_key_pothik_2026';
    const refreshSecret =
      this.configService.get<string>('jwt.refreshSecret') || 'super_secret_refresh_key_pothik_2026';

    const accessToken = this.jwtService.sign(payload, {
      secret: accessSecret,
      expiresIn: '15m',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: refreshSecret,
      expiresIn: '7d',
    });

    return { accessToken, refreshToken };
  }
}
