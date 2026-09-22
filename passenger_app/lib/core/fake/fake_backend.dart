import 'dart:async';
import 'dart:math';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/chat/domain/chat_message.dart';
import '../../features/places/data/places_repository.dart';
import '../../features/places/domain/saved_place.dart';
import '../../features/profile/domain/account_settings.dart';
import '../../features/rides/data/ride_repository.dart';
import '../../features/rides/domain/ride_models.dart';
import '../../features/sos/data/sos_repository.dart';
import '../location/location_service.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';
import 'fake_store.dart';

/// In-memory backend used when `USE_FAKE_BACKEND=true` (dev only).
///
/// It deliberately mirrors the *server's* rules — idempotency keys, OTP
/// throttling, chat closing on trip end, share-link TTL — so the UI is
/// exercised against realistic behaviour, not a yes-machine.
final class FakeWorld {
  FakeWorld({Random? random, this.store}) : _rng = random ?? Random(42);

  final Random _rng;
  final FakeAccountStore? store;
  final Duration latency = const Duration(milliseconds: 450);

  // Auth
  User? user;
  final Map<String, List<DateTime>> otpRequests = {};

  /// Dev/fake OTP for every number. The seeded QA account below is the
  /// canonical test passenger.
  static const String testPhone = '+8801521700014';
  static const String testOtp = '123466';
  static const String devOtp = testOtp;

  static const User testUser = User(
    id: 'u-test-014',
    phone: testPhone,
    name: 'Test Passenger',
    email: 'test@pothik.app',
    locale: 'bn',
  );

  static const EmergencyContact seedContact = EmergencyContact(
    id: 'c1',
    name: 'আম্মু',
    phone: '+8801711000000',
    relation: 'Mother',
  );

  // Rides
  Ride? activeRide;
  Timer? _lifecycle;
  final Map<String, Ride> rides = {};
  final Map<String, String> idempotentResponses = {};
  final Map<String, FareQuote> quotes = {};
  final Map<String, ShareLink> shareLinks = {};
  final List<ChatMessage> messages = [];
  final List<EmergencyContact> contacts = [seedContact];
  final List<SavedPlace> savedPlaces = [];
  final List<RideSummary> rideHistory = [];
  AccountSettings settings = const AccountSettings();
  SosAlert? lastSos;

  FakeAccount snapshot() => FakeAccount(
    user: user!,
    contacts: List.of(contacts),
    savedPlaces: List.of(savedPlaces),
    history: List.of(rideHistory),
    settings: settings,
  );

  void apply(FakeAccount account) {
    user = account.user;
    contacts
      ..clear()
      ..addAll(account.contacts);
    savedPlaces
      ..clear()
      ..addAll(account.savedPlaces);
    rideHistory
      ..clear()
      ..addAll(account.history);
    settings = account.settings;
  }

  Future<void> persist() async {
    final u = user;
    final s = store;
    if (u == null || s == null) return;
    await s.save(u.phone, snapshot());
  }

  void _clearEphemeral() {
    _lifecycle?.cancel();
    activeRide = null;
    rides.clear();
    messages.clear();
    quotes.clear();
    idempotentResponses.clear();
    shareLinks.clear();
    lastSos = null;
  }

  /// Load this phone's saved profile/contacts/history, or seed a new account.
  Future<User> activateAccount(String phone) async {
    await persist();
    _clearEphemeral();
    final saved = await store?.load(phone);
    if (saved != null) {
      apply(saved);
      await store?.setLastPhone(phone);
      return user!;
    }
    if (phone == testPhone) {
      user = testUser;
      contacts
        ..clear()
        ..add(seedContact);
      rideHistory
        ..clear()
        ..addAll(_seededHistory());
      settings = AccountSettings.seed(phone);
    } else {
      user = User(id: 'u-${phone.hashCode.abs()}', phone: phone, locale: 'bn');
      contacts.clear();
      rideHistory.clear();
      settings = AccountSettings.seed(phone);
    }
    savedPlaces.clear();
    await persist();
    await store?.setLastPhone(phone);
    return user!;
  }

  List<RideSummary> _seededHistory() => List.generate(23, (i) {
    final a = catalogue[i % catalogue.length];
    final b = catalogue[(i + 3) % catalogue.length];
    final t = VehicleType.values[i % 3];
    return RideSummary(
      id: 'h$i',
      status: i % 7 == 0 ? RideStatus.cancelled : RideStatus.completed,
      pickupName: a.name,
      dropoffName: b.name,
      fare: 120 + (i * 37) % 400,
      vehicleType: t,
      createdAt: DateTime.now().subtract(Duration(days: i, hours: i * 3)),
    );
  });

  void recordHistory(Ride r) {
    if (!r.status.isTerminal) return;
    final summary = RideSummary(
      id: r.id,
      status: r.status,
      pickupName: r.pickup.name,
      dropoffName: r.dropoff.name,
      fare: r.fare,
      vehicleType: r.vehicleType,
      createdAt: r.createdAt,
    );
    rideHistory.removeWhere((h) => h.id == summary.id);
    rideHistory.insert(0, summary);
    unawaited(persist());
  }

  void ensureHistorySeeded() {
    if (rideHistory.isNotEmpty) return;
    rideHistory.addAll(_seededHistory());
    unawaited(persist());
  }

  Future<T> _lag<T>(T Function() fn) => Future<T>.delayed(latency, fn);

  // Dhaka reference points.
  static const List<Place> catalogue = [
    Place(
      id: 'p1',
      name: 'Gulshan 2 Circle',
      address: 'Gulshan, Dhaka 1212',
      lat: 23.7925,
      lng: 90.4078,
    ),
    Place(
      id: 'p2',
      name: 'Banani 11',
      address: 'Banani, Dhaka 1213',
      lat: 23.7937,
      lng: 90.4040,
    ),
    Place(
      id: 'p3',
      name: 'Dhanmondi 27',
      address: 'Dhanmondi, Dhaka 1209',
      lat: 23.7561,
      lng: 90.3742,
    ),
    Place(
      id: 'p4',
      name: 'Uttara Sector 7',
      address: 'Uttara, Dhaka 1230',
      lat: 23.8697,
      lng: 90.3997,
    ),
    Place(
      id: 'p5',
      name: 'Motijheel Shapla Chattar',
      address: 'Motijheel, Dhaka 1000',
      lat: 23.7276,
      lng: 90.4180,
    ),
    Place(
      id: 'p6',
      name: 'Hazrat Shahjalal Intl Airport',
      address: 'Kurmitola, Dhaka 1229',
      lat: 23.8433,
      lng: 90.3978,
    ),
    Place(
      id: 'p7',
      name: 'Bashundhara City',
      address: 'Panthapath, Dhaka 1205',
      lat: 23.7508,
      lng: 90.3906,
    ),
    Place(
      id: 'p8',
      name: 'Mirpur 10 Circle',
      address: 'Mirpur, Dhaka 1216',
      lat: 23.8069,
      lng: 90.3687,
    ),
    Place(
      id: 'p9',
      name: 'New Market',
      address: 'Azimpur, Dhaka 1205',
      lat: 23.7336,
      lng: 90.3854,
    ),
    Place(
      id: 'p10',
      name: 'Jamuna Future Park',
      address: 'Kuril, Dhaka 1229',
      lat: 23.8135,
      lng: 90.4244,
    ),
    Place(
      id: 'p11',
      name: 'Gazipur Chowrasta',
      address: 'Joydebpur, Gazipur 1700 · গাজীপুর চৌরাস্তা',
      lat: 23.9999,
      lng: 90.4203,
    ),
    Place(
      id: 'p12',
      name: 'Joydebpur Railway Station',
      address: 'Joydebpur, Gazipur 1700',
      lat: 24.0005,
      lng: 90.4260,
    ),
    Place(
      id: 'p13',
      name: 'Chandana Chowrasta',
      address: 'Chandana, Gazipur 1702',
      lat: 23.9965,
      lng: 90.4220,
    ),
    Place(
      id: 'p14',
      name: 'Tongi Bazar',
      address: 'Tongi, Gazipur 1710',
      lat: 23.8914,
      lng: 90.4023,
    ),
    Place(
      id: 'p15',
      name: 'Board Bazar',
      address: 'Board Bazar, Gazipur 1704',
      lat: 23.9482,
      lng: 90.3815,
    ),
    Place(
      id: 'p16',
      name: 'National University',
      address: 'Board Bazar, Gazipur 1704',
      lat: 23.9488,
      lng: 90.3798,
    ),
    Place(
      id: 'p17',
      name: 'Gazipur Bus Terminal',
      address: 'Maleker Bari, Gazipur 1700',
      lat: 24.0020,
      lng: 90.4250,
    ),
    Place(
      id: 'p18',
      name: 'Bhawal National Park',
      address: 'Bhawal, Gazipur 1703',
      lat: 24.0833,
      lng: 90.4000,
    ),
    Place(
      id: 'p19',
      name: 'Konabari',
      address: 'Konabari, Gazipur 1750',
      lat: 23.9920,
      lng: 90.3480,
    ),
    Place(
      id: 'p20',
      name: 'Pubail',
      address: 'Pubail, Gazipur 1721',
      lat: 23.9200,
      lng: 90.4520,
    ),
    Place(
      id: 'p21',
      name: 'Vogra Bypass',
      address: 'Vogra, Gazipur 1700',
      lat: 24.0120,
      lng: 90.3920,
    ),
    Place(
      id: 'p22',
      name: 'Sreepur Bazar',
      address: 'Sreepur, Gazipur 1740',
      lat: 24.2010,
      lng: 90.4700,
    ),
    Place(
      id: 'p23',
      name: 'Kaliakair Chowrasta',
      address: 'Kaliakair, Gazipur 1750',
      lat: 24.0750,
      lng: 90.2180,
    ),
    Place(
      id: 'p24',
      name: 'Narayanganj Terminal',
      address: 'Narayanganj 1400 · নারায়ণগঞ্জ',
      lat: 23.6238,
      lng: 90.5000,
    ),
    Place(
      id: 'p25',
      name: 'Savar Bus Stand',
      address: 'Savar, Dhaka 1340 · সাভার',
      lat: 23.8583,
      lng: 90.2667,
    ),
    Place(
      id: 'p26',
      name: 'Ashulia',
      address: 'Ashulia, Savar, Dhaka 1341',
      lat: 23.8970,
      lng: 90.3220,
    ),
    Place(
      id: 'p27',
      name: 'Chattogram Railway Station',
      address: 'Station Road, Chattogram 4000 · চট্টগ্রাম',
      lat: 22.3320,
      lng: 91.8320,
    ),
    Place(
      id: 'p28',
      name: 'Agrabad',
      address: 'Agrabad, Chattogram 4100',
      lat: 22.3239,
      lng: 91.8117,
    ),
    Place(
      id: 'p29',
      name: 'GEC Circle',
      address: 'GEC, Chattogram 4000',
      lat: 22.3592,
      lng: 91.8215,
    ),
    Place(
      id: 'p30',
      name: 'Sylhet Ambarkhana',
      address: 'Ambarkhana, Sylhet 3100 · সিলেট',
      lat: 24.8949,
      lng: 91.8687,
    ),
    Place(
      id: 'p31',
      name: 'Osmani International Airport',
      address: 'Sylhet 3100',
      lat: 24.9632,
      lng: 91.8668,
    ),
    Place(
      id: 'p32',
      name: 'Khulna City',
      address: 'Khulna 9100 · খুলনা',
      lat: 22.8456,
      lng: 89.5403,
    ),
    Place(
      id: 'p33',
      name: 'Rajshahi Court',
      address: 'Rajshahi 6000 · রাজশাহী',
      lat: 24.3745,
      lng: 88.6042,
    ),
    Place(
      id: 'p34',
      name: 'Barishal Sadar',
      address: 'Barishal 8200 · বরিশাল',
      lat: 22.7010,
      lng: 90.3535,
    ),
    Place(
      id: 'p35',
      name: 'Rangpur Terminal',
      address: 'Rangpur 5400 · রংপুর',
      lat: 25.7439,
      lng: 89.2752,
    ),
    Place(
      id: 'p36',
      name: 'Cumilla Kandirpar',
      address: 'Kandirpar, Cumilla 3500 · কুমিল্লা',
      lat: 23.4607,
      lng: 91.1809,
    ),
    Place(
      id: 'p37',
      name: 'Mymensingh Town Hall',
      address: 'Mymensingh 2200 · ময়মনসিংহ',
      lat: 24.7471,
      lng: 90.4203,
    ),
    Place(
      id: 'p38',
      name: "Cox's Bazar Beach",
      address: "Kolatoli, Cox's Bazar 4700 · কক্সবাজার",
      lat: 21.4272,
      lng: 91.9712,
    ),
    Place(
      id: 'p39',
      name: 'Teknaf',
      address: "Teknaf, Cox's Bazar 4760",
      lat: 20.8624,
      lng: 92.3058,
    ),
    Place(
      id: 'p40',
      name: 'Bandarban Town',
      address: 'Bandarban 4600 · বান্দরবান',
      lat: 22.1953,
      lng: 92.2183,
    ),
    Place(
      id: 'p41',
      name: 'Rangamati',
      address: 'Rangamati 4500 · রাঙামাটি',
      lat: 22.6573,
      lng: 92.1733,
    ),
    Place(
      id: 'p42',
      name: 'Jashore Town',
      address: 'Jashore 7400 · যশোর',
      lat: 23.1664,
      lng: 89.2081,
    ),
    Place(
      id: 'p43',
      name: 'Bogura Satmatha',
      address: 'Satmatha, Bogura 5800 · বগুড়া',
      lat: 24.8481,
      lng: 89.3730,
    ),
    Place(
      id: 'p44',
      name: 'Kuakata Sea Beach',
      address: 'Kuakata, Patuakhali 8650 · কুয়াকাটা',
      lat: 21.8210,
      lng: 90.1215,
    ),
    Place(
      id: 'p45',
      name: 'Saint Martin Island',
      address: "St. Martin's Island, Cox's Bazar · সেন্ট মার্টিন",
      lat: 20.6283,
      lng: 92.3222,
    ),
  ];

  static const _driver = Driver(
    id: 'd1',
    name: 'Rahim Uddin',
    rating: 4.8,
    vehiclePlate: 'ঢাকা মেট্রো-হ ১২-৩৪৫৬',
    vehicleModel: 'Toyota Axio',
    vehicleColor: 'Silver',
    maskedPhone: '+8801*******21',
    totalTrips: 1240,
  );

  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double d) => d * pi / 180;

  num fareFor(VehicleType t, int meters, int seconds) {
    final km = meters / 1000;
    final (base, perKm, perMin) = switch (t) {
      VehicleType.bike => (30, 12, 1.0),
      VehicleType.cng => (50, 18, 1.5),
      VehicleType.car => (80, 28, 2.5),
    };
    final raw = base + perKm * km + perMin * (seconds / 60);
    return (raw / 5).round() * 5;
  }

  void _advanceRide(Ride Function(Ride) update) {
    final r = activeRide;
    if (r == null) return;
    final next = update(r);
    rides[next.id] = next;
    activeRide = next.status.isActive ? next : null;
    if (next.status.isTerminal) recordHistory(next);
  }

  /// Simulates dispatch → acceptance → driver movement → trip → payment.
  void startLifecycle(Ride ride, {required bool noDriver}) {
    _lifecycle?.cancel();
    activeRide = ride;
    rides[ride.id] = ride;

    if (noDriver) {
      _lifecycle = Timer(const Duration(seconds: 8), () {
        _advanceRide((r) => r.copyWith(status: RideStatus.noDriver));
      });
      return;
    }

    var tick = 0;
    final pickup = ride.pickup;
    final drop = ride.dropoff;
    // Driver starts ~1.2km away from pickup.
    var dLat = pickup.lat + 0.008;
    var dLng = pickup.lng + 0.006;

    _lifecycle = Timer.periodic(const Duration(seconds: 2), (t) {
      tick++;
      final r = activeRide;
      if (r == null) {
        t.cancel();
        return;
      }
      switch (r.status) {
        case RideStatus.searching:
          if (tick >= 3) {
            _advanceRide(
              (r) => r.copyWith(
                status: RideStatus.accepted,
                driver: _driver,
                otp: '4821',
                driverLocation: DriverLocation(
                  lat: dLat,
                  lng: dLng,
                  at: DateTime.now().toUtc(),
                  etaSeconds: 240,
                  distanceMeters: 1200,
                ),
              ),
            );
          }
        case RideStatus.accepted:
        case RideStatus.arriving:
          dLat += (pickup.lat - dLat) * 0.25;
          dLng += (pickup.lng - dLng) * 0.25;
          final dist = haversineMeters(dLat, dLng, pickup.lat, pickup.lng);
          final arrived = dist < 40;
          _advanceRide(
            (r) => r.copyWith(
              status: arrived ? RideStatus.arrived : RideStatus.arriving,
              driverLocation: DriverLocation(
                lat: dLat,
                lng: dLng,
                at: DateTime.now().toUtc(),
                etaSeconds: (dist / 6).round(),
                distanceMeters: dist.round(),
              ),
            ),
          );
        case RideStatus.arrived:
          // Driver "enters the OTP" after a short wait.
          if (tick % 5 == 0) {
            _advanceRide((r) => r.copyWith(status: RideStatus.inProgress));
          }
        case RideStatus.inProgress:
          dLat += (drop.lat - dLat) * 0.18;
          dLng += (drop.lng - dLng) * 0.18;
          final dist = haversineMeters(dLat, dLng, drop.lat, drop.lng);
          if (dist < 60) {
            final total = r.fare;
            _advanceRide(
              (r) => r.copyWith(
                status: RideStatus.paymentPending,
                completedAt: DateTime.now().toUtc(),
                breakdown: FareBreakdown(
                  base: (total * 0.3).round(),
                  distanceCharge: (total * 0.55).round(),
                  timeCharge:
                      total - (total * 0.3).round() - (total * 0.55).round(),
                  total: total,
                ),
              ),
            );
            // Fake driver says thanks in chat.
            _driverSays(r.id, 'ধন্যবাদ! ভালো থাকবেন।');
          } else {
            _advanceRide(
              (r) => r.copyWith(
                driverLocation: DriverLocation(
                  lat: dLat,
                  lng: dLng,
                  at: DateTime.now().toUtc(),
                  etaSeconds: (dist / 8).round(),
                  distanceMeters: dist.round(),
                ),
              ),
            );
          }
        case RideStatus.paymentPending:
        case RideStatus.completed:
        case RideStatus.cancelled:
        case RideStatus.noDriver:
          t.cancel();
      }
    });
  }

  void _driverSays(String tripId, String text) {
    messages.add(
      ChatMessage(
        id: 'm${messages.length + 1}',
        tripId: tripId,
        sender: ChatSender.driver,
        text: text,
        sentAt: DateTime.now().toUtc(),
      ),
    );
  }

  void driverAutoReply(String tripId) {
    Timer(const Duration(seconds: 2), () {
      final replies = ['আসছি ২ মিনিটে।', 'ঠিক আছে।', 'গেটের সামনে দাঁড়ান।'];
      _driverSays(tripId, replies[_rng.nextInt(replies.length)]);
    });
  }

  void dispose() => _lifecycle?.cancel();
}

// ---------------------------------------------------------------------------

final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._w, this._tokens);

  final FakeWorld _w;
  final TokenStorage _tokens;

  @override
  Future<OtpChallenge> requestOtp(String phone) => _w._lag(() {
    final now = DateTime.now();
    final list = _w.otpRequests.putIfAbsent(phone, () => [])
      ..removeWhere((t) => now.difference(t) > const Duration(minutes: 10));
    if (list.length >= 3) {
      throw ApiException(
        code: ApiErrorCode.rateLimited,
        statusCode: 429,
        retryAfter: const Duration(minutes: 10) - now.difference(list.first),
      );
    }
    list.add(now);
    return OtpChallenge(
      phone: phone,
      resendAfter: const Duration(seconds: 30),
      expiresIn: const Duration(minutes: 5),
    );
  });

  @override
  Future<User> verifyOtp({required String phone, required String code}) async {
    await Future<void>.delayed(_w.latency);
    if (code != FakeWorld.devOtp) {
      throw const ApiException(
        code: ApiErrorCode.validation,
        statusCode: 422,
        serverCode: ServerErrorCodes.otpInvalid,
      );
    }
    await _tokens.write(
      AuthTokens(
        accessToken: 'fake-access',
        refreshToken: 'fake-refresh',
        accessExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    return _w.activateAccount(phone);
  }

  @override
  Future<User?> currentUser() async {
    if (await _tokens.read() == null) return null;
    if (_w.user != null) return _w._lag(() => _w.user);
    final phone = _w.store?.lastPhone;
    if (phone == null) return null;
    return _w.activateAccount(phone);
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? locale,
    String? photoUrl,
    bool clearPhoto = false,
    String? username,
    Gender? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
  }) async {
    await Future<void>.delayed(_w.latency);
    final u = _w.user!;
    final next = u.copyWith(
      name: name,
      email: email,
      locale: locale,
      photoUrl: photoUrl,
      clearPhoto: clearPhoto,
      username: username,
      gender: gender,
      dateOfBirth: dateOfBirth,
      clearDateOfBirth: clearDateOfBirth,
    );
    _w.user = next;
    await _w.persist();
    return next;
  }

  @override
  Future<User> changePhone({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(_w.latency);
    if (code != FakeWorld.devOtp) {
      throw const ApiException(
        code: ApiErrorCode.validation,
        statusCode: 422,
        serverCode: ServerErrorCodes.otpInvalid,
      );
    }
    final old = _w.user!.phone;
    final next = _w.user!.copyWith(phone: phone);
    _w.user = next;
    await _w.persist();
    if (old != phone) await _w.store?.delete(old);
    await _w.store?.setLastPhone(phone);
    return next;
  }

  @override
  Future<void> deleteAccount() async {
    final phone = _w.user?.phone;
    if (phone != null) await _w.store?.delete(phone);
    _w.user = null;
    _w.contacts.clear();
    _w.savedPlaces.clear();
    _w.rideHistory.clear();
    _w.settings = const AccountSettings();
    await _w.store?.setLastPhone(null);
    await _tokens.clear();
  }

  @override
  Future<void> registerDevice({required String pushToken}) async {}

  @override
  Future<void> logout() async {
    await _w.persist();
    await _w.store?.setLastPhone(null);
    await _tokens.clear();
  }

  @override
  Future<List<EmergencyContact>> emergencyContacts() =>
      _w._lag(() => List.of(_w.contacts));

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? relation,
  }) async {
    await Future<void>.delayed(_w.latency);
    if (_w.contacts.length >= 3) {
      throw const ApiException(
        code: ApiErrorCode.validation,
        statusCode: 422,
        fieldErrors: {
          'contacts': ['max 3'],
        },
      );
    }
    final c = EmergencyContact(
      id: 'c${_w.contacts.length + 1}${_w._rng.nextInt(999)}',
      name: name,
      phone: phone,
      relation: relation,
    );
    _w.contacts.add(c);
    await _w.persist();
    return c;
  }

  @override
  Future<void> removeEmergencyContact(String id) async {
    await Future<void>.delayed(_w.latency);
    _w.contacts.removeWhere((c) => c.id == id);
    await _w.persist();
  }
}

// ---------------------------------------------------------------------------

final class FakeRideRepository implements RideRepository {
  FakeRideRepository(this._w);

  final FakeWorld _w;

  @override
  Future<FareQuote> estimate({required Place pickup, required Place dropoff}) =>
      _w._lag(() {
        final m = FakeWorld.haversineMeters(
          pickup.lat,
          pickup.lng,
          dropoff.lat,
          dropoff.lng,
        ).round();
        final meters = max(400, (m * 1.35).round()); // road factor
        final seconds = (meters / 5.5).round(); // ~20 km/h Dhaka traffic
        final q = FareQuote(
          quoteId: 'q${DateTime.now().microsecondsSinceEpoch}',
          pickup: pickup,
          dropoff: dropoff,
          estimates: [
            for (final t in VehicleType.values)
              FareEstimate(
                vehicleType: t,
                fare: _w.fareFor(t, meters, seconds),
                distanceMeters: meters,
                durationSeconds: seconds,
                surgeMultiplier: t == VehicleType.car ? 1.2 : 1.0,
                etaToPickupSeconds: switch (t) {
                  VehicleType.bike => 180,
                  VehicleType.cng => 300,
                  VehicleType.car => 240,
                },
              ),
          ],
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 3)),
        );
        _w.quotes[q.quoteId] = q;
        return q;
      });

  @override
  Future<Ride> book({
    required String quoteId,
    required VehicleType vehicleType,
    required String idempotencyKey,
    String? note,
  }) => _w._lag(() {
    final existingId = _w.idempotentResponses[idempotencyKey];
    if (existingId != null) return _w.rides[existingId]!;
    if (_w.activeRide != null) {
      throw const ApiException(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        serverCode: ServerErrorCodes.activeRideExists,
      );
    }
    final q = _w.quotes[quoteId];
    if (q == null || q.isExpired) {
      throw const ApiException(
        code: ApiErrorCode.validation,
        statusCode: 422,
        fieldErrors: {
          'quote_id': ['expired'],
        },
      );
    }
    final est = q.forVehicle(vehicleType)!;
    final ride = Ride(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      status: RideStatus.searching,
      pickup: q.pickup,
      dropoff: q.dropoff,
      vehicleType: vehicleType,
      fare: est.fare,
      distanceMeters: est.distanceMeters,
      durationSeconds: est.durationSeconds,
      createdAt: DateTime.now().toUtc(),
    );
    _w.idempotentResponses[idempotencyKey] = ride.id;
    _w.startLifecycle(
      ride,
      noDriver: q.dropoff.name.toLowerCase().contains('nodriver'),
    );
    return ride;
  });

  @override
  Future<Ride?> activeRide() => _w._lag(() => _w.activeRide);

  @override
  Future<Ride> getRide(String id) => Future.delayed(
    const Duration(milliseconds: 200),
    () {
      final r = _w.rides[id];
      if (r == null) {
        throw const ApiException(code: ApiErrorCode.notFound, statusCode: 404);
      }
      return r;
    },
  );

  @override
  Future<Ride> cancel(String id, CancelReason reason) => _w._lag(() {
    final r = _w.rides[id]!;
    if (!r.status.isCancellableByPassenger) {
      throw const ApiException(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        serverCode: ServerErrorCodes.rideNotCancellable,
      );
    }
    _w._lifecycle?.cancel();
    final next = r.copyWith(
      status: RideStatus.cancelled,
      cancelReason: reason.wire,
    );
    _w.rides[id] = next;
    _w.activeRide = null;
    _w.recordHistory(next);
    return next;
  });

  @override
  Future<Ride> confirmCash(
    String id, {
    required String idempotencyKey,
  }) => _w._lag(() {
    final r = _w.rides[id]!;
    // Idempotent: a duplicate key (or an already-confirmed ride) returns
    // the same completed ride and triggers no second side-effect.
    if (_w.idempotentResponses.containsKey(idempotencyKey) || r.cashConfirmed) {
      return _w.rides[id]!;
    }
    if (r.status != RideStatus.paymentPending) {
      throw const ApiException(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        serverCode: ServerErrorCodes.tripNotActive,
      );
    }
    _w.idempotentResponses[idempotencyKey] = id;
    final next = r.copyWith(status: RideStatus.completed, cashConfirmed: true);
    _w.rides[id] = next;
    _w.activeRide = null;
    _w.recordHistory(next);
    return next;
  });

  @override
  Future<void> rate(String id, {required int stars, String? comment}) =>
      _w._lag(() {
        _w.rides[id] = _w.rides[id]!.copyWith(rated: true);
      });

  @override
  Future<void> publishLocation(String id, GeoPoint point) async {
    final r = _w.rides[id];
    if (r == null || !r.status.isActive) {
      throw const ApiException(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        serverCode: ServerErrorCodes.tripNotActive,
      );
    }
  }

  @override
  Future<ShareLink> createShareLink(String id) => _w._lag(() {
    final token = List.generate(
      32,
      (_) => _w._rng.nextInt(16).toRadixString(16),
    ).join();
    final link = ShareLink(
      url: 'https://track.pothik.app/t/$token',
      token: token,
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 3)),
    );
    _w.shareLinks[id] = link;
    return link;
  });

  @override
  Future<void> revokeShareLink(String id) =>
      _w._lag(() => _w.shareLinks.remove(id));

  @override
  Future<Page<RideSummary>> history({String? cursor, int limit = 20}) =>
      _w._lag(() {
        _w.ensureHistorySeeded();
        final live = _w.rides.values.where((r) => r.status.isTerminal);
        for (final r in live) {
          if (!_w.rideHistory.any((h) => h.id == r.id)) {
            _w.rideHistory.insert(
              0,
              RideSummary(
                id: r.id,
                status: r.status,
                pickupName: r.pickup.name,
                dropoffName: r.dropoff.name,
                fare: r.fare,
                vehicleType: r.vehicleType,
                createdAt: r.createdAt,
              ),
            );
          }
        }
        final all = List<RideSummary>.of(_w.rideHistory)
          ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
        final start = cursor == null ? 0 : int.parse(cursor);
        final end = min(all.length, start + limit);
        return Page(
          items: all.sublist(start, end),
          nextCursor: end < all.length ? '$end' : null,
        );
      });

  @override
  Future<String> authorizeChannel(String socketId, String channel) async =>
      'fake:auth';
}

// ---------------------------------------------------------------------------

final class FakeChatRepository implements ChatRepository {
  FakeChatRepository(this._w);

  final FakeWorld _w;

  @override
  Future<List<ChatMessage>> messages(String tripId) => Future.delayed(
    const Duration(milliseconds: 200),
    () => _w.messages.where((m) => m.tripId == tripId).toList(),
  );

  @override
  Future<ChatMessage> send(
    String tripId, {
    required String text,
    required String clientId,
  }) => _w._lag(() {
    final r = _w.rides[tripId];
    if (r == null || !r.status.isTracking) {
      throw const ApiException(
        code: ApiErrorCode.conflict,
        statusCode: 409,
        serverCode: ServerErrorCodes.chatClosed,
      );
    }
    final existing = _w.messages.where((m) => m.clientId == clientId);
    if (existing.isNotEmpty) return existing.first;
    final m = ChatMessage(
      id: 'm${_w.messages.length + 1}',
      tripId: tripId,
      sender: ChatSender.passenger,
      text: text,
      sentAt: DateTime.now().toUtc(),
      clientId: clientId,
    );
    _w.messages.add(m);
    _w.driverAutoReply(tripId);
    return m;
  });
}

// ---------------------------------------------------------------------------

final class FakeSosRepository implements SosRepository {
  FakeSosRepository(this._w);

  final FakeWorld _w;

  @override
  Future<SosAlert> trigger({
    required String idempotencyKey,
    String? rideId,
    GeoPoint? location,
  }) => _w._lag(() {
    final last = _w.lastSos;
    // Server-side dedup window: one active alert per 60s.
    if (last != null &&
        DateTime.now().difference(last.createdAt) <
            const Duration(seconds: 60)) {
      return last;
    }
    return _w.lastSos = SosAlert(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      rideId: rideId,
      createdAt: DateTime.now(),
      contactsNotified: _w.contacts.length,
    );
  });
}

// ---------------------------------------------------------------------------

final class FakePlacesRepository implements PlacesRepository {
  FakePlacesRepository(this._w);

  final FakeWorld _w;

  @override
  Future<List<Place>> search(String query, {GeoPoint? near}) => _w._lag(() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    if (q.contains('nodriver')) {
      return const [
        Place(
          id: 'x',
          name: 'NoDriver Test Point',
          address: 'Simulates no drivers available',
          lat: 23.78,
          lng: 90.40,
        ),
      ];
    }
    final folded = _foldQuery(q);
    return FakeWorld.catalogue.where((p) {
      final hay = _foldQuery('${p.name} ${p.address}');
      return hay.contains(folded);
    }).toList();
  });

  /// Common Romanisation / Bangla aliases so "Gazpur", "গাজীপুর" still hit.
  static String _foldQuery(String s) {
    var t = s.toLowerCase();
    const aliases = <String, String>{
      'gazpur': 'gazipur',
      'gazipor': 'gazipur',
      'gaazipur': 'gazipur',
      'গাজীপুর': 'gazipur',
      'গাজিপুর': 'gazipur',
      'naryanganj': 'narayanganj',
      'নারায়ণগঞ্জ': 'narayanganj',
      'নারায়নগঞ্জ': 'narayanganj',
      'সাভার': 'savar',
    };
    for (final e in aliases.entries) {
      t = t.replaceAll(e.key, e.value);
    }
    return t;
  }

  @override
  Future<Place?> reverseGeocode(GeoPoint point) => _w._lag(
    () => Place(
      name: 'Current location',
      address: 'Road near ${FakeWorld.catalogue[1].address}',
      lat: point.lat,
      lng: point.lng,
    ),
  );

  @override
  Future<List<SavedPlace>> saved() => _w._lag(() => List.of(_w.savedPlaces));

  @override
  Future<SavedPlace> save({
    required SavedPlaceKind kind,
    required String label,
    required Place place,
  }) async {
    await Future<void>.delayed(_w.latency);
    final s = SavedPlace(
      id: 'sp${_w.savedPlaces.length + 1}${_w._rng.nextInt(999)}',
      kind: kind,
      label: label,
      place: place,
    );
    _w.savedPlaces.add(s);
    await _w.persist();
    return s;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(_w.latency);
    _w.savedPlaces.removeWhere((s) => s.id == id);
    await _w.persist();
  }
}
