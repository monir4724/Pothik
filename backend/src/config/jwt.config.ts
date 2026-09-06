import { registerAs } from '@nestjs/config';

export default registerAs('jwt', () => ({
  accessSecret: process.env.JWT_ACCESS_SECRET || 'super_secret_access_key_pothik_2026',
  accessExpiration: process.env.JWT_ACCESS_EXPIRATION || '15m',
  refreshSecret: process.env.JWT_REFRESH_SECRET || 'super_secret_refresh_key_pothik_2026',
  refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d',
}));
