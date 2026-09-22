// These tests pin the *server rules* the UI depends on, using the fake
// backend as the executable spec. The same assertions belong in the Laravel
// feature suite (production build doc §8).
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/fake/fake_backend.dart';
import 'package:pothik_passenger/core/fake/fake_store.dart';
import 'package:pothik_passenger/core/location/location_service.dart';
import 'package:pothik_passenger/core/network/api_exception.dart';
import 'package:pothik_passenger/core/storage/token_storage.dart';
import 'package:pothik_passenger/features/rides/domain/ride_models.dart';

void main() {
  late FakeWorld world;
  late FakeRideRepository rides;

  const pickup = Place(name: 'A', address: '', lat: 23.79, lng: 90.40);
  const dropoff = Place(name: 'B', address: '', lat: 23.75, lng: 90.37);

  setUp(() {
    world = FakeWorld();
    rides = FakeRideRepository(world);
  });

  tearDown(() => world.dispose());

  test('fare comes from the server quote; client cannot supply it', () async {
    final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
    final ride = await rides.book(
      quoteId: q.quoteId,
      vehicleType: VehicleType.cng,
      idempotencyKey: 'k1',
    );
    // The booking API has no fare parameter at all; the persisted fare is
    // exactly the server's quoted value.
    expect(ride.fare, q.forVehicle(VehicleType.cng)!.fare);
  });

  test(
    'booking is idempotent on the key (double-tap / retry after timeout)',
    () async {
      final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
      final a = await rides.book(
        quoteId: q.quoteId,
        vehicleType: VehicleType.bike,
        idempotencyKey: 'same',
      );
      final b = await rides.book(
        quoteId: q.quoteId,
        vehicleType: VehicleType.bike,
        idempotencyKey: 'same',
      );
      expect(a.id, b.id);
      expect(world.rides.length, 1);
    },
  );

  test(
    'second booking with a new key while one is active → 409 ACTIVE_RIDE_EXISTS',
    () async {
      final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
      await rides.book(
        quoteId: q.quoteId,
        vehicleType: VehicleType.bike,
        idempotencyKey: 'k1',
      );
      expect(
        () => rides.book(
          quoteId: q.quoteId,
          vehicleType: VehicleType.bike,
          idempotencyKey: 'k2',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCode.conflict)
              .having(
                (e) => e.serverCode,
                'serverCode',
                ServerErrorCodes.activeRideExists,
              ),
        ),
      );
    },
  );

  test('cash-confirm is idempotent: one completion side-effect', () async {
    final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
    final ride = await rides.book(
      quoteId: q.quoteId,
      vehicleType: VehicleType.car,
      idempotencyKey: 'k',
    );
    // Force the ride into payment_pending without waiting on timers.
    world.rides[ride.id] = ride.copyWith(status: RideStatus.paymentPending);
    world.activeRide = world.rides[ride.id];

    final first = await rides.confirmCash(ride.id, idempotencyKey: 'confirm-1');
    final second = await rides.confirmCash(
      ride.id,
      idempotencyKey: 'confirm-1',
    );
    final thirdWithNewKey = await rides.confirmCash(
      ride.id,
      idempotencyKey: 'confirm-2',
    );

    expect(first.status, RideStatus.completed);
    expect(first.cashConfirmed, isTrue);
    expect(second, first);
    expect(thirdWithNewKey.cashConfirmed, isTrue);
    expect(world.activeRide, isNull);
    expect(
      world.idempotentResponses.keys
          .where((k) => k.startsWith('confirm'))
          .length,
      1,
      reason: 'only the first confirm is recorded as a side-effect',
    );
  });

  test('cash-confirm before payment_pending is rejected (409)', () async {
    final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
    final ride = await rides.book(
      quoteId: q.quoteId,
      vehicleType: VehicleType.car,
      idempotencyKey: 'k',
    );
    expect(
      () => rides.confirmCash(ride.id, idempotencyKey: 'c'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.conflict,
        ),
      ),
    );
  });

  test(
    'passenger location push is rejected once the trip is not active',
    () async {
      final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
      final ride = await rides.book(
        quoteId: q.quoteId,
        vehicleType: VehicleType.bike,
        idempotencyKey: 'k',
      );
      world.rides[ride.id] = ride.copyWith(status: RideStatus.completed);
      expect(
        () => rides.publishLocation(ride.id, const GeoPoint(23.7, 90.4)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.serverCode,
            'code',
            ServerErrorCodes.tripNotActive,
          ),
        ),
      );
    },
  );

  test('SOS dedups rapid double-trigger into one alert', () async {
    final sos = FakeSosRepository(world);
    final a = await sos.trigger(idempotencyKey: 'a');
    final b = await sos.trigger(idempotencyKey: 'b');
    expect(a.id, b.id);
  });

  test('chat send is refused once trip is finished', () async {
    final chat = FakeChatRepository(world);
    final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
    final ride = await rides.book(
      quoteId: q.quoteId,
      vehicleType: VehicleType.bike,
      idempotencyKey: 'k',
    );
    world.rides[ride.id] = ride.copyWith(status: RideStatus.completed);
    expect(
      () => chat.send(ride.id, text: 'hi', clientId: 'c1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.serverCode,
          'code',
          ServerErrorCodes.chatClosed,
        ),
      ),
    );
  });

  test('OTP request is throttled to 3 per 10 minutes per phone', () async {
    final auth = FakeAuthRepository(world, InMemoryTokenStorage());
    const phone = '+8801712345678';
    await auth.requestOtp(phone);
    await auth.requestOtp(phone);
    await auth.requestOtp(phone);
    expect(
      () => auth.requestOtp(phone),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          ApiErrorCode.rateLimited,
        ),
      ),
    );
  });

  test('share link is a 32-hex unguessable token with a TTL', () async {
    final q = await rides.estimate(pickup: pickup, dropoff: dropoff);
    final ride = await rides.book(
      quoteId: q.quoteId,
      vehicleType: VehicleType.bike,
      idempotencyKey: 'k',
    );
    final link = await rides.createShareLink(ride.id);
    expect(link.token, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(link.isExpired, isFalse);
    expect(link.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  });

  test('history is paginated by cursor', () async {
    final p1 = await rides.history(limit: 10);
    expect(p1.items, hasLength(10));
    expect(p1.hasMore, isTrue);
    final p2 = await rides.history(cursor: p1.nextCursor, limit: 10);
    expect(p2.items.first.id, isNot(p1.items.first.id));
  });

  test('seeded test passenger logs in with dedicated OTP', () async {
    final tokens = InMemoryTokenStorage();
    final auth = FakeAuthRepository(world, tokens);
    await expectLater(
      auth.verifyOtp(phone: FakeWorld.testPhone, code: '000000'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.serverCode,
          'code',
          ServerErrorCodes.otpInvalid,
        ),
      ),
    );
    final user = await auth.verifyOtp(
      phone: FakeWorld.testPhone,
      code: FakeWorld.testOtp,
    );
    expect(user.id, FakeWorld.testUser.id);
    expect(user.phone, '+8801521700014');
    expect(user.name, 'Test Passenger');
    expect(user.isProfileComplete, isTrue);
    expect((await tokens.read())?.accessToken, isNotEmpty);
  });

  test('profile, contacts and history persist across login', () async {
    final store = MemoryFakeAccountStore();
    final world = FakeWorld(store: store);
    addTearDown(world.dispose);
    final auth = FakeAuthRepository(world, InMemoryTokenStorage());
    final rides = FakeRideRepository(world);

    await auth.verifyOtp(
      phone: FakeWorld.testPhone,
      code: FakeWorld.testOtp,
    );
    await auth.updateProfile(name: 'Updated Passenger', email: 'a@b.c');
    await auth.addEmergencyContact(
      name: 'Baba',
      phone: '+8801711222333',
      relation: 'Father',
    );
    final history = await rides.history(limit: 50);

    final world2 = FakeWorld(store: store);
    addTearDown(world2.dispose);
    final auth2 = FakeAuthRepository(world2, InMemoryTokenStorage());
    final rides2 = FakeRideRepository(world2);
    final user = await auth2.verifyOtp(
      phone: FakeWorld.testPhone,
      code: FakeWorld.testOtp,
    );

    expect(user.name, 'Updated Passenger');
    expect(user.email, 'a@b.c');
    final contacts = await auth2.emergencyContacts();
    expect(contacts.map((c) => c.name), containsAll(['আম্মু', 'Baba']));
    final restored = await rides2.history(limit: 50);
    expect(restored.items.length, history.items.length);
    expect(restored.items.first.id, history.items.first.id);
  });
}
