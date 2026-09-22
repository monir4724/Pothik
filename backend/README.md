# Pothik Backend (NestJS)

Production-oriented API for the Pothik ride-hailing platform (OTP auth, passenger
& driver flows, rides, realtime).

Monorepo root: [github.com/monir4724/Pothik](https://github.com/monir4724/Pothik)

## Requirements

- Node.js 20+
- Docker Desktop (Postgres + Redis via `docker-compose.yml`), **or** local
  Postgres/PostGIS + Redis matching `.env`

## Setup

```bash
cp .env.example .env
docker compose up -d postgres redis   # if Docker is available
npm install
npm run prisma:generate
npm run prisma:migrate                # when schema is ready
npm run start:dev
```

- HTTP: `http://localhost:3000`
- API prefix: `/api/v1` (see `API_PREFIX` in `.env`)

## Scripts

| Script | Purpose |
| ------ | ------- |
| `npm run start:dev` | Watch mode |
| `npm run build` | Compile |
| `npm run start:prod` | Run `dist` |
| `npm run prisma:generate` | Generate Prisma client |
| `npm run prisma:migrate` | Dev migrations |
| `npm run prisma:seed` | Seed data |

## Notes

- Prisma client must match `src/database/prisma/schema.prisma`. After schema
  changes run `npm run prisma:generate` or Nest will fail with missing model
  errors (e.g. `otpSession`).
- Passenger Flutter app can use this API by setting
  `USE_FAKE_BACKEND=false` and `API_BASE_URL=http://localhost:3000/api/v1`
  (use `10.0.2.2` for Android emulator).

## Related

- Passenger app: [`../passenger_app`](../passenger_app)
- Web frontend: [`../frontend`](../frontend)
