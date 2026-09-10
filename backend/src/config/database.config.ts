import { registerAs } from '@nestjs/config';

export default registerAs('database', () => ({
  url: process.env.DATABASE_URL || 'postgresql://pothik_user:pothik_password@localhost:5432/pothik_db?schema=public',
}));
