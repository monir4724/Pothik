import 'package:dio/dio.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';

final class SosAlert {
  const SosAlert({
    required this.id,
    required this.createdAt,
    this.rideId,
    this.contactsNotified = 0,
  });

  factory SosAlert.fromJson(Map<String, Object?> j) => SosAlert(
    id: j['id'].toString(),
    rideId: j['ride_id']?.toString(),
    createdAt: DateTime.parse(j['created_at'] as String),
    contactsNotified: (j['contacts_notified'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String? rideId;
  final DateTime createdAt;
  final int contactsNotified;
}

abstract interface class SosRepository {
  /// POST /sos — server dedups rapid double-triggers into one active alert;
  /// the idempotency key makes a retried request safe too.
  Future<SosAlert> trigger({
    required String idempotencyKey,
    String? rideId,
    GeoPoint? location,
  });
}

final class RemoteSosRepository implements SosRepository {
  RemoteSosRepository(this._api);

  final ApiClient _api;

  @override
  Future<SosAlert> trigger({
    required String idempotencyKey,
    String? rideId,
    GeoPoint? location,
  }) => guardApi(() async {
    final r = await _api.dio.post<Object?>(
      '/sos',
      data: {'ride_id': ?rideId, 'lat': ?location?.lat, 'lng': ?location?.lng},
      options: Options(
        headers: {kIdempotencyKeyHeader: idempotencyKey},
        // SOS must not hang the UI; short timeout + client retry.
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final body = r.data as Map<String, Object?>;
    return SosAlert.fromJson((body['data'] ?? body) as Map<String, Object?>);
  });
}
