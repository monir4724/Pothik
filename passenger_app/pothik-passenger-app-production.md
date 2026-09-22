# পথিক (Pothik) — Passenger App — Production-Level Build Doc

Status: Production-hardening layer on top of the Final Master Build Doc. Written from a senior-developer review pass — this file does not replace the master doc's feature/architecture spec, it adds what's required to run this app with real passengers, real money (cash today, digital payout later), and real emergency (SOS) traffic.

Read together with: Passenger App Master Build Doc (features/screens/API), Driver App Master Build Doc, Driver App Production-Level Build Doc.

---

## 1. Why this file exists

The master doc gets the Passenger App to **MVP**: real driver interconnection, real tracking, real chat. It does not yet specify what's needed for **Production Ready** status:

- a passenger's account/session can't be taken over
- fare can't be manipulated client-side
- a dropped connection mid-trip doesn't strand the UI
- an outage triggers an alert, not a support ticket flood
- KYC-adjacent passenger data (phone, location history, emergency contacts) is handled with real privacy discipline

This doc follows the three-tier maturity model (MVP → Production Ready → Production Scale) and states, per area, what's added versus the master doc.

---

## 2. Database update: Supabase (Postgres) replacing MySQL

**Decision:** database only, matching the Driver App's Production-Level Build Doc. Laravel stays the backend framework; Redis, Laravel Reverb, and JWT auth are unchanged. MySQL 8 is replaced by Supabase's managed Postgres — Supabase's own Auth/Realtime/Storage products are **not** used, so Laravel remains the single source of truth for both apps, preserving the master doc's core "apps never talk to each other, everything goes through the API" principle.

### 2.1 `.env` changes
```
DB_CONNECTION=pgsql
DB_HOST=your-supabase-project.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-supabase-db-password
```
This is one shared Laravel backend serving both apps, so this is a single migration, not something done twice — the Driver App doc's Section 2 covers the same change in more depth (atomic-accept concurrency, migration syntax, pooling). Apply those checks once, they cover both apps' data.

### 2.2 What matters specifically for this app's data
- **Fare/booking transactions:** the `Ride`, `Transaction`, and `RideDispatchAttempt` tables (Section 9 of the master doc) move over via standard Laravel migrations — audit for MySQL-specific column types or raw SQL the same way as the Driver App.
- **Idempotency mechanism for cash-confirm** (Section 4.2 below): if implemented via a unique constraint or a dedicated idempotency-key table, verify the constraint syntax is valid Postgres (mostly identical to MySQL, but double-check `ON CONFLICT` vs MySQL's `ON DUPLICATE KEY` if that pattern is used anywhere).
- **Guardian share-link tokens:** if stored with an expiry/lookup index, confirm the index carries over correctly in the Postgres migration — this is a security-relevant table (Section 4.3), worth an explicit check rather than assuming migration success.

### 2.3 Backup/restore impact (Section 6)
Same guidance as the Driver App doc: Supabase's built-in Postgres backups are complementary to, not a replacement for, the independent encrypted off-site backup and restore-drill requirement below.

---

## 3. Current state vs target (gap summary)

| Area | Master doc has | Production Ready needs |
|---|---|---|
| Auth | OTP login, JWT | Refresh-token rotation, JWT blacklist on logout, rate limiting on OTP endpoints |
| Fare integrity | "Client-submitted fare is never trusted; server always recalculates" (already correct) | Enforce this with a test, not just a doc line — plus rate-limit the estimate endpoint against scraping/abuse |
| Input validation | Implied | Form Request validation server-side on every authenticated endpoint |
| Error handling | Per-screen edge cases | Global exception handler, consistent error shape, correct HTTP codes |
| Logging/monitoring | Not specified | Crash reporting, structured logs, uptime/queue/Reverb monitoring, alerting |
| Testing | Manual checklist only | Automated feature tests, idempotency test for cash-confirm, SOS dedup test |
| CI/CD | Not specified | Git flow, staged environments, rollback plan, migration safety |
| Backups | Not specified | Automated backups + restore drills |
| Privacy | Not specified | Retention policy for location/chat history, guardian-share-link expiry, privacy policy |

---

## 4. Security hardening (Passenger App specific)

### 4.1 Authentication & session
- OTP request/verify: rate-limit **3 requests / 10 min per phone number** (already noted in master doc's throttle line — enforce it, don't just document it), plus per-IP throttling to blunt distributed abuse.
- JWT access token short-lived; refresh token rotated and revocable. Blacklist on logout via the Redis-backed `tymon/jwt-auth` blacklist already in the stack.
- Device-token binding for push notifications — invalidate stale tokens on login from a new device.

### 4.2 Fare and payment integrity
- Re-confirm server-side: the client never supplies fare, distance, or duration for the final charge — the master doc states this correctly; add an automated test asserting a tampered client payload is ignored and the server-computed fare wins.
- Cash-confirm idempotency: the master doc flags this as a requirement — implement via an idempotency key (e.g. ride ID + a server-issued confirm token) so a retried/double-tapped request can't double-count a payment event or double-trigger downstream effects (rating unlock, receipt, etc.).
- Rate-limit `/rides/estimate` — it's unauthenticated-adjacent in spirit (cheap to call, easy to scrape for competitive fare intelligence) even though it sits behind auth.

### 4.3 Location and chat data
- `PassengerLocationUpdate` publishing: validate the passenger is actually attached to an active trip before accepting a location push — don't let a stale/replayed request write to a trip that's already completed.
- Chat (`trip.{tripId}` messages): disable sending once trip is completed/cancelled (already specified) — enforce server-side, not just by hiding the input client-side.
- Guardian share link (`/rides/{id}/share-link`): must be **unguessable** (long random token, not a sequential ID) and **auto-expire** shortly after trip completion — a live-forever tracking link is a stalking vector, not just a UX nicety.

### 4.4 Standard hardening
- HTTPS everywhere, HSTS.
- Secure headers on any web-facing surface (guardian tracking page).
- Server-side validation via Laravel Form Requests on every authenticated endpoint.
- Dependency vulnerability scanning in CI.

---

## 5. Error handling & observability

- Global exception handler (`app/Exceptions/Handler.php`) with a consistent JSON error envelope and correct HTTP codes: 401/403/404/409/422/429/500 mapped meaningfully (e.g. 409 when trying to book while an active ride already exists).
- Flutter side: map error codes to friendly copy, in the language toggle (BN/EN) the app already supports — never surface raw server error text.
- Crash reporting (Sentry/Firebase Crashlytics) from the first production build.
- Structured logs for: auth events, booking/cancel events, cash-confirm, SOS triggers. Scrub PII (exact GPS trails, phone numbers) before any log leaves the primary system.
- Uptime monitoring: API health, Reverb endpoint, SMS gateway.
- Alerting: SOS trigger pages ops immediately; queue backlog, Reverb disconnect spikes, and booking-failure-rate spikes all get alerts, not just dashboards someone checks later.

---

## 6. Database reliability

- Foreign keys/constraints across `Ride`, `Transaction`, `Rating`, `Message`, `SosAlert`, etc.
- Indexes on `rides.status`, `rides.passenger_id`, `messages.trip_id` + timestamp.
- Transactions around booking (ride creation + dispatch-attempt logging) so a partial failure doesn't leave an orphaned `Ride` row with no dispatch record.
- N+1 prevention on trip history and ride-detail endpoints — eager-load driver/vehicle/rating relations.
- Migrations reversible and tested against production-like data volume.
- Automated encrypted off-site backups with scheduled restore drills. Define RPO/RTO explicitly (e.g. RPO 24h, RTO 4h to start).

---

## 7. Performance & scale readiness

- Booking flow (`POST /rides` → dispatch → `TripAccepted`) is the critical low-latency path — keep it off any slow synchronous work; push SMS/push-notification side effects to a queue.
- Load test the "Finding Driver" path specifically: concurrent bookings against a limited pool of online drivers, to validate the dispatch/accept race behaves correctly under real concurrency (this exercises the same atomic-accept lock the Driver App relies on).
- CDN for any static assets (place-search icons, onboarding illustrations).
- Pagination on trip history — don't return a passenger's entire ride history in one unbounded query as the account ages.

---

## 8. Testing (automated, beyond the manual checklist)

The master doc's "Testing checklist before real-device rollout" is solid manual QA. Add as automated tests:

- Feature tests per endpoint (auth, profile, rides/*, trips/*, sos/*) covering happy path + auth failure + validation failure.
- **Fare-tampering test**: submit a booking/cash-confirm with a manipulated client-side fare value, assert the server-computed value is what's persisted and charged.
- **Cash-confirm idempotency test**: fire the same confirm request twice, assert only one completion side-effect occurs.
- SOS dedup test: trigger twice rapidly, assert one active alert.
- Guardian share-link test: assert the link 404s/expires after the trip completes or after its TTL.
- CI-run regression suite blocking merge on failure.
- Thin E2E covering: login → book → driver assigned (simulated) → OTP shown → trip active → complete → rate.

---

## 9. CI/CD & deployment

- Same git-flow and environment separation as the Driver App: feature branch → PR + review → staging → production.
- CI: static analysis (Larastan/PHPStan, `flutter analyze`), automated test suite, build artifacts.
- Rollback plan documented and rehearsed at least once before public launch.
- Migration safety: additive-first, destructive changes deployed separately once old code paths are gone.
- Secrets (Reverb keys, SMS gateway, Google Maps key, JWT secret) in the CI/CD secret store, never committed, never left as the literal example values from the master doc's `.env` snippet.

---

## 10. Privacy & governance

- Emergency contacts and SOS data: minimum-necessary retention, access restricted, and passengers should be able to see/update their own emergency contact list (already implied by the Profile module — make the retention/visibility rule explicit).
- Location history retention window defined (fraud/dispute window is normally enough) — don't default to "keep everything forever."
- Guardian tracking link: time-boxed and revocable by the passenger before it naturally expires.
- Privacy policy and terms covering: location tracking during trips, SOS data sharing with emergency contacts, chat message retention, and what's shared with the Driver App vs kept passenger-only. Required before public launch, not an afterthought once users start asking.

---

## 11. Revised build order (production-aware)

Supersedes the master doc's build order by inserting hardening where it's cheapest to add:

1. Auth (OTP), profile, BN/EN toggle — **with rate limiting and Form Request validation from the start**
2. Home map, place search, fare estimate — **with the estimate endpoint rate-limited**
3. Book ride + Reverb subscription — **booking wrapped in a DB transaction**
4. Tracking screen (driver marker, distance/ETA) — **with reconnect/backoff and polling fallback tested**
5. Passenger location publish — **with active-trip-ownership check server-side before accepting a push**
6. OTP display, trip started/active UI
7. Chat — **send disabled server-side once trip is completed/cancelled**
8. Trip complete, cash confirm, rating — **cash-confirm idempotency test written alongside this step**
9. SOS — **dedup gating and delivery-failure alerting wired before first real user**; guardian share-link with expiry and revoke
10. History screen (paginated from the start) + polling fallback
11. CI/CD pipeline stood up **in parallel with step 1**, not after feature work is "done"

---

## 12. Production-readiness checklist (Passenger App)

### Database (Supabase/Postgres)
- [ ] Fare/booking table migrations reviewed for MySQL-specific syntax
- [ ] Cash-confirm idempotency mechanism verified valid on Postgres
- [ ] Guardian share-link token index confirmed intact after migration
- [ ] Connection pooler mode matched to Laravel's connection handling (shared check with Driver App)
- [ ] Supabase's built-in backups confirmed as complementary to, not a replacement for, the independent backup/restore requirement

### Security
- [ ] Rate limiting on OTP endpoints and `/rides/estimate`
- [ ] JWT blacklist on logout, refresh-token rotation
- [ ] Server-side Form Request validation on every authenticated endpoint
- [ ] Fare/distance/duration always server-recalculated, never trusted from client
- [ ] Cash-confirm idempotency enforced with a test
- [ ] Guardian share-link unguessable + auto-expiring + passenger-revocable
- [ ] Dependency vulnerability scan in CI

### Reliability
- [ ] Global exception handler with consistent error envelope + correct status codes
- [ ] Crash reporting wired (Sentry/Crashlytics)
- [ ] Structured logging on auth, booking, cash-confirm, SOS events
- [ ] Uptime + queue + Reverb monitoring with alerting
- [ ] Automated DB backups, encrypted, off-site, with tested restore procedure

### Testing & CI/CD
- [ ] Automated feature test suite (per endpoint)
- [ ] Fare-tampering test
- [ ] Cash-confirm idempotency test
- [ ] SOS dedup test
- [ ] CI pipeline: lint + static analysis + tests on every PR
- [ ] Staging environment mirroring production
- [ ] Documented, rehearsed rollback procedure

### Privacy & governance
- [ ] Privacy policy + terms published before public launch
- [ ] Location/chat retention windows defined
- [ ] Emergency-contact and SOS data access restricted + auditable

### Scale readiness (flag for later, don't block launch on these)
- [ ] Load test on the booking/dispatch path at expected peak concurrency
- [ ] Paginated trip history from day one
- [ ] CDN for static assets
- [ ] API versioning if third parties ever integrate
