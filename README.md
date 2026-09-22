# Pothik

Ride-hailing platform for Bangladesh — Bangla passenger & driver experience.

**Repository:** [github.com/monir4724/Pothik](https://github.com/monir4724/Pothik)

## Monorepo layout

| Path | What it is |
| ---- | ---------- |
| [`passenger_app/`](./passenger_app) | Flutter **passenger** mobile/web app |
| [`backend/`](./backend) | NestJS API (OTP auth, rides, drivers, realtime) |
| [`frontend/`](./frontend) | Vite + React admin / web frontend |

## Quick start

### Passenger app (Flutter)

```bash
cd passenger_app
flutter pub get
flutter run -d chrome --web-hostname=localhost --web-port=8080 \
  --dart-define-from-file=env/dev.example.json
```

- Dev uses an in-process **fake backend** (`USE_FAKE_BACKEND=true`) — no API server required.
- Test passenger: `+8801521700014` · OTP `123466`
- Open: **http://localhost:8080**

See [`passenger_app/README.md`](./passenger_app/README.md) for Maps keys, environments, and architecture.

### Backend (NestJS)

```bash
cd backend
cp .env.example .env          # set DATABASE_URL, Redis, secrets
docker compose up -d          # Postgres + Redis (Docker Desktop required)
npm install
npm run prisma:generate
npm run start:dev
```

API default: **http://localhost:3000/api/v1**

See [`backend/README.md`](./backend/README.md) when present, or `backend/package.json` scripts.

### Web frontend (Vite)

```bash
cd frontend
npm install
npm run dev
```

See [`frontend/README.md`](./frontend/README.md).

## Branches (overview)

| Branch | Focus |
| ------ | ----- |
| `main` | Stable / landing |
| `Backend` | NestJS API work |
| `Frontend` | Vite web UI |
| `passenger-app` | Flutter passenger app + monorepo docs |

## Docs

- `passenger_app/pothik-passenger-ui-production.md` — passenger UI/UX production checklist  
- `passenger_app/pothik-passenger-app-production.md` — client ↔ API contract  

## License

UNLICENSED / private project — see package manifests.
