import 'package:equatable/equatable.dart';

final class Place extends Equatable {
  const Place({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.id,
  });

  factory Place.fromJson(Map<String, Object?> j) => Place(
    id: j['id']?.toString(),
    name: j['name'] as String? ?? '',
    address: j['address'] as String? ?? '',
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
  );

  final String? id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
  };

  @override
  List<Object?> get props => [id, name, address, lat, lng];
}

enum VehicleType {
  bike('bike', 1),
  cng('cng', 3),
  car('car', 4);

  const VehicleType(this.wire, this.capacity);

  final String wire;
  final int capacity;

  static VehicleType fromWire(String w) =>
      values.firstWhere((v) => v.wire == w, orElse: () => VehicleType.car);
}

final class FareEstimate extends Equatable {
  const FareEstimate({
    required this.vehicleType,
    required this.fare,
    required this.distanceMeters,
    required this.durationSeconds,
    this.surgeMultiplier = 1.0,
    this.etaToPickupSeconds,
  });

  factory FareEstimate.fromJson(Map<String, Object?> j) => FareEstimate(
    vehicleType: VehicleType.fromWire(j['vehicle_type'] as String),
    fare: (j['fare'] as num),
    distanceMeters: (j['distance_m'] as num).toInt(),
    durationSeconds: (j['duration_s'] as num).toInt(),
    surgeMultiplier: (j['surge'] as num?)?.toDouble() ?? 1.0,
    etaToPickupSeconds: (j['eta_pickup_s'] as num?)?.toInt(),
  );

  final VehicleType vehicleType;
  final num fare;
  final int distanceMeters;
  final int durationSeconds;
  final double surgeMultiplier;
  final int? etaToPickupSeconds;

  bool get hasSurge => surgeMultiplier > 1.0;

  @override
  List<Object?> get props => [
    vehicleType,
    fare,
    distanceMeters,
    durationSeconds,
    surgeMultiplier,
  ];
}

/// A server-issued quote. Booking references [quoteId]; the server
/// recomputes fare from the quote, never from a client-sent number.
final class FareQuote extends Equatable {
  const FareQuote({
    required this.quoteId,
    required this.pickup,
    required this.dropoff,
    required this.estimates,
    required this.expiresAt,
  });

  factory FareQuote.fromJson(Map<String, Object?> j) => FareQuote(
    quoteId: j['quote_id'] as String,
    pickup: Place.fromJson(j['pickup'] as Map<String, Object?>),
    dropoff: Place.fromJson(j['dropoff'] as Map<String, Object?>),
    estimates: (j['estimates'] as List)
        .map((e) => FareEstimate.fromJson(e as Map<String, Object?>))
        .toList(),
    expiresAt: DateTime.parse(j['expires_at'] as String),
  );

  final String quoteId;
  final Place pickup;
  final Place dropoff;
  final List<FareEstimate> estimates;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  FareEstimate? forVehicle(VehicleType t) =>
      estimates.where((e) => e.vehicleType == t).firstOrNull;

  @override
  List<Object?> get props => [quoteId, pickup, dropoff, estimates, expiresAt];
}

enum RideStatus {
  searching('searching'),
  accepted('accepted'),
  arriving('arriving'),
  arrived('arrived'),
  inProgress('in_progress'),
  paymentPending('payment_pending'),
  completed('completed'),
  cancelled('cancelled'),
  noDriver('no_driver');

  const RideStatus(this.wire);

  final String wire;

  static RideStatus fromWire(String w) =>
      values.firstWhere((v) => v.wire == w, orElse: () => RideStatus.cancelled);

  /// Passenger still has a live ride that the UI must resume into.
  bool get isActive => switch (this) {
    searching ||
    accepted ||
    arriving ||
    arrived ||
    inProgress ||
    paymentPending => true,
    completed || cancelled || noDriver => false,
  };

  /// Driver assigned and trip not yet finished — tracking screen territory.
  bool get isTracking => switch (this) {
    accepted || arriving || arrived || inProgress => true,
    _ => false,
  };

  bool get isTerminal => !isActive;

  /// Passenger can cancel without penalty logic on the client side; the
  /// server is authoritative and may reject with RIDE_NOT_CANCELLABLE.
  bool get isCancellableByPassenger => switch (this) {
    searching || accepted || arriving || arrived => true,
    _ => false,
  };
}

final class Driver extends Equatable {
  const Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.vehiclePlate,
    required this.vehicleModel,
    this.vehicleColor,
    this.photoUrl,
    this.maskedPhone,
    this.totalTrips,
  });

  factory Driver.fromJson(Map<String, Object?> j) => Driver(
    id: j['id'].toString(),
    name: j['name'] as String,
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    vehiclePlate: j['vehicle_plate'] as String? ?? '',
    vehicleModel: j['vehicle_model'] as String? ?? '',
    vehicleColor: j['vehicle_color'] as String?,
    photoUrl: j['photo_url'] as String?,
    maskedPhone: j['masked_phone'] as String?,
    totalTrips: (j['total_trips'] as num?)?.toInt(),
  );

  final String id;
  final String name;
  final double rating;
  final String vehiclePlate;
  final String vehicleModel;
  final String? vehicleColor;
  final String? photoUrl;

  /// Server-masked; the app never receives the driver's real number.
  final String? maskedPhone;
  final int? totalTrips;

  @override
  List<Object?> get props => [id, name, rating, vehiclePlate];
}

final class DriverLocation extends Equatable {
  const DriverLocation({
    required this.lat,
    required this.lng,
    required this.at,
    this.bearing,
    this.etaSeconds,
    this.distanceMeters,
  });

  factory DriverLocation.fromJson(Map<String, Object?> j) => DriverLocation(
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    bearing: (j['bearing'] as num?)?.toDouble(),
    etaSeconds: (j['eta_s'] as num?)?.toInt(),
    distanceMeters: (j['distance_m'] as num?)?.toInt(),
    at: j['at'] == null
        ? DateTime.now().toUtc()
        : DateTime.parse(j['at'] as String),
  );

  final double lat;
  final double lng;
  final double? bearing;
  final int? etaSeconds;
  final int? distanceMeters;
  final DateTime at;

  bool get isStale =>
      DateTime.now().toUtc().difference(at.toUtc()) >
      const Duration(seconds: 45);

  @override
  List<Object?> get props => [lat, lng, at];
}

final class FareBreakdown extends Equatable {
  const FareBreakdown({
    required this.base,
    required this.distanceCharge,
    required this.timeCharge,
    required this.total,
    this.surgeCharge = 0,
    this.discount = 0,
  });

  factory FareBreakdown.fromJson(Map<String, Object?> j) => FareBreakdown(
    base: j['base'] as num,
    distanceCharge: j['distance'] as num,
    timeCharge: j['time'] as num,
    surgeCharge: j['surge'] as num? ?? 0,
    discount: j['discount'] as num? ?? 0,
    total: j['total'] as num,
  );

  final num base;
  final num distanceCharge;
  final num timeCharge;
  final num surgeCharge;
  final num discount;
  final num total;

  @override
  List<Object?> get props => [base, distanceCharge, timeCharge, total];
}

final class Ride extends Equatable {
  const Ride({
    required this.id,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.vehicleType,
    required this.fare,
    required this.createdAt,
    this.driver,
    this.otp,
    this.driverLocation,
    this.breakdown,
    this.distanceMeters,
    this.durationSeconds,
    this.completedAt,
    this.cashConfirmed = false,
    this.rated = false,
    this.cancelReason,
  });

  factory Ride.fromJson(Map<String, Object?> j) => Ride(
    id: j['id'].toString(),
    status: RideStatus.fromWire(j['status'] as String),
    pickup: Place.fromJson(j['pickup'] as Map<String, Object?>),
    dropoff: Place.fromJson(j['dropoff'] as Map<String, Object?>),
    vehicleType: VehicleType.fromWire(j['vehicle_type'] as String),
    fare: j['fare'] as num,
    createdAt: DateTime.parse(j['created_at'] as String),
    driver: j['driver'] == null
        ? null
        : Driver.fromJson(j['driver'] as Map<String, Object?>),
    otp: j['otp'] as String?,
    driverLocation: j['driver_location'] == null
        ? null
        : DriverLocation.fromJson(j['driver_location'] as Map<String, Object?>),
    breakdown: j['fare_breakdown'] == null
        ? null
        : FareBreakdown.fromJson(j['fare_breakdown'] as Map<String, Object?>),
    distanceMeters: (j['distance_m'] as num?)?.toInt(),
    durationSeconds: (j['duration_s'] as num?)?.toInt(),
    completedAt: j['completed_at'] == null
        ? null
        : DateTime.parse(j['completed_at'] as String),
    cashConfirmed: j['cash_confirmed'] as bool? ?? false,
    rated: j['rated'] as bool? ?? false,
    cancelReason: j['cancel_reason'] as String?,
  );

  final String id;
  final RideStatus status;
  final Place pickup;
  final Place dropoff;
  final VehicleType vehicleType;

  /// Always server-computed. The client never sends a fare.
  final num fare;
  final DateTime createdAt;
  final Driver? driver;

  /// 4-digit trip-start OTP the passenger reads to the driver.
  final String? otp;
  final DriverLocation? driverLocation;
  final FareBreakdown? breakdown;
  final int? distanceMeters;
  final int? durationSeconds;
  final DateTime? completedAt;
  final bool cashConfirmed;
  final bool rated;
  final String? cancelReason;

  Ride copyWith({
    RideStatus? status,
    Driver? driver,
    String? otp,
    DriverLocation? driverLocation,
    FareBreakdown? breakdown,
    num? fare,
    DateTime? completedAt,
    bool? cashConfirmed,
    bool? rated,
    String? cancelReason,
  }) => Ride(
    id: id,
    status: status ?? this.status,
    pickup: pickup,
    dropoff: dropoff,
    vehicleType: vehicleType,
    fare: fare ?? this.fare,
    createdAt: createdAt,
    driver: driver ?? this.driver,
    otp: otp ?? this.otp,
    driverLocation: driverLocation ?? this.driverLocation,
    breakdown: breakdown ?? this.breakdown,
    distanceMeters: distanceMeters,
    durationSeconds: durationSeconds,
    completedAt: completedAt ?? this.completedAt,
    cashConfirmed: cashConfirmed ?? this.cashConfirmed,
    rated: rated ?? this.rated,
    cancelReason: cancelReason ?? this.cancelReason,
  );

  @override
  List<Object?> get props => [
    id,
    status,
    fare,
    driver,
    otp,
    driverLocation,
    cashConfirmed,
    rated,
  ];
}

final class RideSummary extends Equatable {
  const RideSummary({
    required this.id,
    required this.status,
    required this.pickupName,
    required this.dropoffName,
    required this.fare,
    required this.vehicleType,
    required this.createdAt,
  });

  factory RideSummary.fromJson(Map<String, Object?> j) => RideSummary(
    id: j['id'].toString(),
    status: RideStatus.fromWire(j['status'] as String),
    pickupName: j['pickup_name'] as String,
    dropoffName: j['dropoff_name'] as String,
    fare: j['fare'] as num,
    vehicleType: VehicleType.fromWire(j['vehicle_type'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  final String id;
  final RideStatus status;
  final String pickupName;
  final String dropoffName;
  final num fare;
  final VehicleType vehicleType;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'status': status.wire,
    'pickup_name': pickupName,
    'dropoff_name': dropoffName,
    'fare': fare,
    'vehicle_type': vehicleType.wire,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [id, status, fare, createdAt];
}

/// Cursor-paginated page. History is paginated from day one (§7).
final class Page<T> {
  const Page({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Guardian share link — unguessable token, short TTL, revocable.
final class ShareLink extends Equatable {
  const ShareLink({
    required this.url,
    required this.token,
    required this.expiresAt,
  });

  factory ShareLink.fromJson(Map<String, Object?> j) => ShareLink(
    url: j['url'] as String,
    token: j['token'] as String,
    expiresAt: DateTime.parse(j['expires_at'] as String),
  );

  final String url;
  final String token;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  @override
  List<Object?> get props => [token, expiresAt];
}

enum CancelReason {
  changedMind('changed_mind'),
  driverTooFar('driver_too_far'),
  wrongPickup('wrong_pickup'),
  driverAskedToCancel('driver_asked'),
  other('other');

  const CancelReason(this.wire);

  final String wire;
}
