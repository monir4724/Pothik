# পথিক (Pothik) — Passenger App

Flutter passenger app for ride-hailing in Bangladesh. Bangla-first, light-first UI,
built for budget Android devices on unreliable networks.

Part of the [Pothik monorepo](https://github.com/monir4724/Pothik).

Design references in this folder:

- `pothik-passenger-ui-production.md` — UI/UX hardening (a11y, l10n, network states)
- `pothik-passenger-app-production.md` — backend contract, security, observability

## Quick start

```bash
flutter pub get
flutter run -d chrome --web-hostname=localhost --web-port=8080 \
  --dart-define-from-file=env/dev.example.json
```

Frontend (web): **http://localhost:8080**

Dev uses the **fake backend** (`USE_FAKE_BACKEND=true` in `env/dev.example.json`) —
OTP, matching, tracking, chat, cash, rating, history and emergency contacts all
run in-process. No Nest/Laravel server required for UI work.

| | |
| -- | -- |
| Test phone | `+8801521700014` |
| Test OTP | `123466` |

### Talk to a real API

```bash
cp env/dev.example.json env/dev.json
# set USE_FAKE_BACKEND=false and API_BASE_URL to your Nest/Laravel host
flutter run --dart-define-from-file=env/dev.json
```

The Nest API in this monorepo lives at [`../backend`](../backend) (default
`http://localhost:3000/api/v1`).

### Google Maps keys

| Platform | Where | Example |
| -------- | ----- | ------- |
| Android | `android/local.properties` → `MAPS_API_KEY=` | keep gitignored |
| iOS | `ios/Flutter/Secrets.xcconfig` → `MAPS_API_KEY=` | keep gitignored |
| Web | `web/index.html` Maps JS script + `MAPS_API_KEY` dart-define | |

Without billing + Places/Geocoding enabled, place **search** falls back to
OpenStreetMap geocoders (Photon / Open-Meteo); the map still uses Google tiles.

## Environments

Compile-time config via `--dart-define-from-file`. See `env/*.example.json`.

| Key | Dev default | Staging / prod |
| --- | ----------- | -------------- |
| `APP_ENV` | `dev` | `staging` / `prod` |
| `API_BASE_URL` | emulator / localhost API | **must** be `https://` |
| `USE_FAKE_BACKEND` | `true` | **must** be `false` |
| `REVERB_*` | local | TLS + real key |
| `MAPS_API_KEY` | local key | restricted key |
| `SENTRY_DSN` | empty (off) | set to enable |

`AppConfig.validate()` refuses non-dev builds that break the bold rules above.

## Architecture

```
lib/
  app/            bootstrap, MaterialApp, router, theme, providers
  core/           config, Dio, realtime, storage, location, fake backend, maps
  features/<f>/   domain / data / presentation
  shared/widgets/ buttons, banners, skeletons, OTP, SOS, map, avatar
  l10n/           app_en.arb, app_bn.arb → generated/
```

- **State:** Riverpod 3 `Notifier`s  
- **Routing:** `go_router` with auth / onboarding / active-ride redirects  
- **Profile:** editable name, photo, username, gender, DOB; payments, promos,
  notifications, security, help — persisted per phone on the fake backend  
- **Search:** Google Places (when billed) + OSM fallback, Bangladesh-only  

## Commands

```bash
flutter analyze --fatal-infos
flutter test
dart run tool/check_l10n.dart
flutter gen-l10n
flutter build appbundle --release --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols
```

## Conventions

- Colours / spacing / type via `AppColors`, `AppSpacing`, `AppTypography`
- All user-visible strings in both `.arb` files
- No `print` — use `AppLogger` (PII scrubbed)
- Network failures → `ApiException` + `ErrorLocalizer`
